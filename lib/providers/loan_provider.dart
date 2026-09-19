import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/models/transaction_model.dart';
import 'package:paywise/services/notification_service.dart';
import 'package:paywise/services/secure_storage_service.dart';

class LoanProvider with ChangeNotifier {
  List<LoanModel> _loans = [];
  StreamSubscription<QuerySnapshot>? _loansSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;
  double _previousMonthOutstanding = -1;

  List<LoanModel> get loans => _loans;
  double get previousMonthOutstanding => _previousMonthOutstanding;

  LoanProvider() {
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user == null) {
          clearUserData();
        } else if (_currentUserId != user.uid) {
          clearUserData();
          _currentUserId = user.uid;
          initLoans();
        }
      });
    } catch (_) {
      // Allows unit testing without initialized Firebase App
    }
  }

  void clearUserData() {
    _loansSubscription?.cancel();
    _loansSubscription = null;
    _loans = [];
    _currentUserId = null;
    _stagedForDeletionIds.clear();
    _stagedIndices.clear();
    _previousMonthOutstanding = -1;
    _hasTriggeredBackfill = false;
    notifyListeners();
  }

  double get totalOutstanding {
    double total = 0;
    for (var loan in _loans) {
      if (!loan.isPaidOff) total += loan.outstandingBalance;
    }
    return total;
  }
  
  double get monthlyOutflow {
    double total = 0;
    for (var loan in _loans) {
      if (!loan.isPaidOff) total += loan.emiAmount;
    }
    return total;
  }

  bool _hasTriggeredBackfill = false;

  void initLoans() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        clearUserData();
        return;
      }

      _currentUserId = user.uid;
      _loansSubscription?.cancel();
      _loansSubscription = FirebaseFirestore.instance
          .collection('loans')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen(
        (snapshot) {
          _loans = snapshot.docs
              .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
              .where((l) => l.userId == user.uid && !_stagedForDeletionIds.contains(l.id))
              .toList();
          _checkAndUpdateMonthlySnapshot();
          _triggerBackfillOnceIfNeeded(_loans);
          notifyListeners();
        },
        onError: (e) {
          debugPrint("Loans fetch error: $e");
        },
      );
    } catch (e) {
      debugPrint("Firebase not initialized in initLoans: $e");
    }
  }

  void _triggerBackfillOnceIfNeeded(List<LoanModel> loans) {
    if (_hasTriggeredBackfill) return;
    final needsBackfill = loans.any((l) => l.lastPaymentDate == null && l.totalPaid > 0);
    if (!needsBackfill) {
      _hasTriggeredBackfill = true;
      return;
    }
    _hasTriggeredBackfill = true;
    // Delay background backfill by 3s so startup UI renders smoothly without any database contention
    Future.delayed(const Duration(seconds: 3), () {
      _backfillMissingLastPaymentDates(loans);
    });
  }

  Future<void> _backfillMissingLastPaymentDates(List<LoanModel> loans) async {
    for (var loan in loans) {
      if (loan.lastPaymentDate == null && loan.totalPaid > 0) {
        try {
          final txns = await FirebaseFirestore.instance
              .collection('loans')
              .doc(loan.id)
              .collection('transactions')
              .orderBy('date', descending: true)
              .limit(1)
              .get();
          if (txns.docs.isNotEmpty) {
            final dateStr = txns.docs.first.data()['date']?.toString();
            if (dateStr != null) {
              await FirebaseFirestore.instance
                  .collection('loans')
                  .doc(loan.id)
                  .update({'lastPaymentDate': dateStr});
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _checkAndUpdateMonthlySnapshot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentTotal = totalOutstanding;
    if (currentTotal <= 0) return;

    try {
      final now = DateTime.now();
      final currentMonthKey = "${now.year}-${now.month}";

      final monthKeySetting = 'lastRecordedMonthKey_${user.uid}';
      final amountKeySetting = 'lastRecordedOutstandingAmount_${user.uid}';

      // Read from Keystore/Keychain secure storage
      String? savedMonthKey = await SecureStorageService.readSecureData(monthKeySetting);
      String? savedAmountStr = await SecureStorageService.readSecureData(amountKeySetting);

      // Seamless migration from legacy SharedPreferences if secure storage entry is empty
      if (savedMonthKey == null || savedAmountStr == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          savedMonthKey ??= prefs.getString(monthKeySetting);
          final legacyAmount = prefs.getDouble(amountKeySetting);
          if (legacyAmount != null) {
            savedAmountStr ??= legacyAmount.toString();
          }
        } catch (_) {}
      }

      final savedAmount = savedAmountStr != null ? double.tryParse(savedAmountStr) : null;

      bool changed = false;
      if (savedMonthKey == null || savedAmount == null) {
        await SecureStorageService.writeSecureData(monthKeySetting, currentMonthKey);
        await SecureStorageService.writeSecureData(amountKeySetting, currentTotal.toString());
        if (_previousMonthOutstanding != currentTotal) {
          _previousMonthOutstanding = currentTotal;
          changed = true;
        }
      } else if (savedMonthKey != currentMonthKey) {
        if (_previousMonthOutstanding != savedAmount) {
          _previousMonthOutstanding = savedAmount;
          changed = true;
        }
        await SecureStorageService.writeSecureData(monthKeySetting, currentMonthKey);
        await SecureStorageService.writeSecureData(amountKeySetting, currentTotal.toString());
      } else {
        if (_previousMonthOutstanding != savedAmount) {
          _previousMonthOutstanding = savedAmount;
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating monthly snapshot: $e");
    }
  }

  // --- RECORD PAYMENT (With Savings Calculation) ---
  Future<Map<String, dynamic>> recordPayment(LoanModel loan, double amount, DateTime date) async {
    
    // 1. Safety Check: Amount
    if (amount <= 0 || amount.isNaN || amount.isInfinite) {
      throw Exception("Payment amount must be greater than zero.");
    }

    if (amount > loan.outstandingBalance + 5) { 
       throw Exception("Payment exceeds outstanding balance!");
    }

    // 1a. Future Date Check: Cannot record payment for future dates
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (date.isAfter(todayEnd)) {
      throw Exception("Future payment dates are not allowed. Select today or a past date.");
    }

    // 1b. Duplicate Payment Check: Only 1 payment allowed per day per loan
    final existingTxns = await FirebaseFirestore.instance
        .collection('loans')
        .doc(loan.id)
        .collection('transactions')
        .get();

    for (var doc in existingTxns.docs) {
      final data = doc.data();
      if (data['date'] != null) {
        final txnDate = DateTime.tryParse(data['date'].toString());
        if (txnDate != null) {
          if (txnDate.year == date.year &&
              txnDate.month == date.month &&
              txnDate.day == date.day) {
            throw Exception(
              "A payment has already been recorded for ${DateFormat('MMM dd, yyyy').format(date)}. Multiple payments on the same date are not allowed.",
            );
          }
        }
      }
    }

    // 2. Add Transaction & Update Balance Atomically via WriteBatch
    double newBalance = loan.outstandingBalance - amount;
    if (newBalance < 10) newBalance = 0; // Auto-close if tiny amount remains
    
    bool isFinished = newBalance == 0;
    double newTotalPaid = loan.totalPaid + amount;

    final batch = FirebaseFirestore.instance.batch();
    final loanDocRef = FirebaseFirestore.instance.collection('loans').doc(loan.id);
    final txnDocRef = loanDocRef.collection('transactions').doc();

    batch.set(txnDocRef, {
      'loanId': loan.id,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': amount > loan.emiAmount ? 'Extra Payment' : 'EMI',
    });

    batch.update(loanDocRef, {
      'outstandingBalance': newBalance,
      'totalPaid': newTotalPaid,
      'isPaidOff': isFinished,
      'lastPaymentDate': date.toIso8601String(),
    });

    await batch.commit();

    // 3. Calculate Savings (Only if Finished)
    if (isFinished) {
      try {
        await NotificationService().cancelReminder(loan.id);
      } catch (_) {}

      // Expected Total vs Actual Total
      double expectedTotal = loan.emiAmount * loan.tenureMonths;
      double actualTotal = newTotalPaid;
      double amountSaved = expectedTotal - actualTotal;
      if (amountSaved < 0) amountSaved = 0;

      // Time Saved
      // Calculate months passed since start
      int monthsPassed = ((DateTime.now().difference(loan.startDate).inDays) / 30).ceil();
      if (monthsPassed < 1) monthsPassed = 1;
      
      int monthsSaved = loan.tenureMonths - monthsPassed;
      if (monthsSaved < 0) monthsSaved = 0;

      return {
        'isPaidOff': true,
        'amountSaved': amountSaved,
        'monthsSaved': monthsSaved
      };
    }

    return {'isPaidOff': false};
  }

  Future<String> addLoan(LoanModel loan) async {
    if (loan.outstandingBalance == 0 && loan.principalAmount > 0) {
      loan.outstandingBalance = loan.principalAmount;
    }

    if (loan.tenureMonths <= 0) {
      throw Exception("Loan tenure must be at least 1 month.");
    }
    
    if (loan.emiAmount == 0) {
        double r = loan.interestRate / 12 / 100;
        double n = loan.tenureMonths.toDouble();
        if (loan.interestRate > 0) {
          loan.emiAmount = (loan.principalAmount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
        } else {
           loan.emiAmount = loan.principalAmount / loan.tenureMonths;
        }
    }

    if (loan.totalPayable <= 0 && loan.emiAmount > 0) {
      loan.totalPayable = loan.emiAmount * loan.tenureMonths;
      loan.totalInterest = max(0.0, loan.totalPayable - loan.principalAmount);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not authenticated. Please log in.");
    }

    final loanMap = loan.toMap();
    loanMap['userId'] = user.uid;
    loanMap['userEmail'] = user.email ?? '';

    DocumentReference docRef = await FirebaseFirestore.instance.collection('loans').add(loanMap);
    return docRef.id; 
  }

  Stream<List<TransactionModel>> getTransactionHistory(String loanId) {
    try {
      return FirebaseFirestore.instance
          .collection('loans')
          .doc(loanId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => 
            snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList()
          );
    } catch (_) {
      return const Stream.empty();
    }
  }

  List<AmortizationRow> getAmortizationSchedule(LoanModel loan) {
    List<AmortizationRow> schedule = [];
    double balance = loan.principalAmount;
    double r = loan.interestRate / 12 / 100;

    for (int i = 1; i <= loan.tenureMonths; i++) {
      double interest = balance * r;
      double principal = loan.emiAmount - interest;
      if (balance - principal < 0) principal = balance;
      balance = balance - principal;
      if (balance < 0.01) balance = 0.0;
      if (i == loan.tenureMonths && balance > 0) {
         principal += balance;
         balance = 0;
      }
      schedule.add(AmortizationRow(i, loan.emiAmount, principal, interest, balance));
    }
    return schedule;
  }

  Future<void> deleteTransaction(String loanId, String transactionId) async {
    final loanRef = FirebaseFirestore.instance.collection('loans').doc(loanId);
    final txnRef = loanRef.collection('transactions').doc(transactionId);

    // 1. Read the transaction amount before deleting
    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) return; // already gone
    final double amount = (txnSnap.data()!['amount'] as num).toDouble();

    // 2. Read current loan values
    final loanSnap = await loanRef.get();
    if (!loanSnap.exists) return;
    final data = loanSnap.data()!;
    final double currentOutstanding = (data['outstandingBalance'] as num).toDouble();
    final double currentTotalPaid   = (data['totalPaid'] as num).toDouble();
    final double principalAmount    = (data['principalAmount'] as num).toDouble();

    // 3. Reverse the payment: add amount back to outstanding, subtract from paid
    final double newOutstanding = (currentOutstanding + amount).clamp(0.0, principalAmount);
    final double newTotalPaid   = (currentTotalPaid - amount).clamp(0.0, double.infinity);
    final bool   stillPaidOff   = newOutstanding <= 0;

    // 4. Fetch remaining transactions to find updated last payment date
    final remainingTxns = await loanRef
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(2)
        .get();

    String? updatedLastPay;
    for (final doc in remainingTxns.docs) {
      if (doc.id != transactionId) {
        updatedLastPay = doc.data()['date'] as String?;
        break;
      }
    }

    // 5. Write changes atomically via a batch
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(txnRef);
    batch.update(loanRef, {
      'outstandingBalance': newOutstanding,
      'totalPaid':          newTotalPaid,
      'isPaidOff':          stillPaidOff,
      'lastPaymentDate':    updatedLastPay,
    });
    await batch.commit();
  }

  final Set<String> _stagedForDeletionIds = {};
  final Map<String, int> _stagedIndices = {};

  // --- SOFT-DELETE STAGING & UNDO RESTORATION ---
  void stageLoanForDeletion(LoanModel loan) {
    _stagedForDeletionIds.add(loan.id);
    final idx = _loans.indexWhere((l) => l.id == loan.id);
    if (idx != -1) {
      _stagedIndices[loan.id] = idx;
    }
    _loans.removeWhere((l) => l.id == loan.id);
    notifyListeners();
    // Intentionally deferred: Firestore deletion occurs only when the 8-second
    // undo toast expires via confirmPermanentDelete, preventing premature data loss.
  }

  void cancelStageLoanDeletion(LoanModel loan) {
    _stagedForDeletionIds.remove(loan.id);
    if (!_loans.any((l) => l.id == loan.id)) {
      final targetIdx = _stagedIndices.remove(loan.id);
      if (targetIdx != null && targetIdx >= 0 && targetIdx <= _loans.length) {
        _loans.insert(targetIdx, loan);
      } else {
        _loans.add(loan);
      }
      notifyListeners();
    }
  }

  Future<void> confirmPermanentDelete(String loanId) async {
    _stagedForDeletionIds.remove(loanId);
    _stagedIndices.remove(loanId);
    await deleteLoan(loanId);
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      // 0. Cancel any scheduled reminders for this loan
      try {
        await NotificationService().cancelReminder(loanId);
      } catch (_) {}

      // 1. Delete all transactions in the sub-collection first
      final txns = await FirebaseFirestore.instance
          .collection('loans')
          .doc(loanId)
          .collection('transactions')
          .get();
      for (final doc in txns.docs) {
        await doc.reference.delete();
      }

      // 2. Delete parent loan document in Firestore
      await FirebaseFirestore.instance.collection('loans').doc(loanId).delete();
    } catch (e) {
      debugPrint("Error purging loan document from Firestore: [REDACTED_ID]");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loansSubscription?.cancel();
    super.dispose();
  }
}
