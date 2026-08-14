import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/models/transaction_model.dart';

class LoanProvider with ChangeNotifier {
  List<LoanModel> _loans = [];
  StreamSubscription<QuerySnapshot>? _loansSubscription;
  double _previousMonthOutstanding = -1;

  List<LoanModel> get loans => _loans;
  double get previousMonthOutstanding => _previousMonthOutstanding;

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

  void initLoans() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _loansSubscription?.cancel();
    _loansSubscription = FirebaseFirestore.instance
        .collection('loans')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _loans = snapshot.docs
          .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
          .where((l) => !_stagedForDeletionIds.contains(l.id))
          .toList();
      _checkAndUpdateMonthlySnapshot();
      notifyListeners();
    });
  }

  Future<void> _checkAndUpdateMonthlySnapshot() async {
    final currentTotal = totalOutstanding;
    if (currentTotal <= 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final currentMonthKey = "${now.year}-${now.month}";

      final savedMonthKey = prefs.getString('lastRecordedMonthKey');
      final savedAmount = prefs.getDouble('lastRecordedOutstandingAmount');

      if (savedMonthKey == null || savedAmount == null) {
        await prefs.setString('lastRecordedMonthKey', currentMonthKey);
        await prefs.setDouble('lastRecordedOutstandingAmount', currentTotal);
        _previousMonthOutstanding = currentTotal;
      } else if (savedMonthKey != currentMonthKey) {
        _previousMonthOutstanding = savedAmount;
        await prefs.setString('lastRecordedMonthKey', currentMonthKey);
        await prefs.setDouble('lastRecordedOutstandingAmount', currentTotal);
      } else {
        _previousMonthOutstanding = savedAmount;
      }
    } catch (e) {
      debugPrint("Error updating monthly snapshot: $e");
    }
  }

  // --- RECORD PAYMENT (With Savings Calculation) ---
  Future<Map<String, dynamic>> recordPayment(LoanModel loan, double amount, DateTime date) async {
    
    // 1. Safety Check: Amount
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

    // 2. Add Transaction
    await FirebaseFirestore.instance.collection('loans').doc(loan.id).collection('transactions').add({
      'loanId': loan.id,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': amount > loan.emiAmount ? 'Extra Payment' : 'EMI',
    });

    // 3. Update Balance
    double newBalance = loan.outstandingBalance - amount;
    if (newBalance < 10) newBalance = 0; // Auto-close if tiny amount remains
    
    bool isFinished = newBalance == 0;
    double newTotalPaid = loan.totalPaid + amount;

    await FirebaseFirestore.instance.collection('loans').doc(loan.id).update({
      'outstandingBalance': newBalance,
      'totalPaid': newTotalPaid,
      'isPaidOff': isFinished
    });

    // 4. Calculate Savings (Only if Finished)
    if (isFinished) {
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
    
    if (loan.emiAmount == 0) {
        double r = loan.interestRate / 12 / 100;
        double n = loan.tenureMonths.toDouble();
        if (loan.interestRate > 0) {
          loan.emiAmount = (loan.principalAmount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
        } else {
           loan.emiAmount = loan.principalAmount / loan.tenureMonths;
        }
    }

    DocumentReference docRef = await FirebaseFirestore.instance.collection('loans').add(loan.toMap());
    return docRef.id; 
  }

  Stream<List<TransactionModel>> getTransactionHistory(String loanId) {
    return FirebaseFirestore.instance
        .collection('loans')
        .doc(loanId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList()
        );
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

    // 4. Write both changes atomically via a batch
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(txnRef);
    batch.update(loanRef, {
      'outstandingBalance': newOutstanding,
      'totalPaid':          newTotalPaid,
      'isPaidOff':          stillPaidOff,
    });
    await batch.commit();
  }

  final Set<String> _stagedForDeletionIds = {};

  // --- SOFT-DELETE STAGING & UNDO RESTORATION ---
  void stageLoanForDeletion(LoanModel loan) {
    _stagedForDeletionIds.add(loan.id);
    _loans.removeWhere((l) => l.id == loan.id);
    notifyListeners();
    // Delete immediately from Firestore so refreshing or restarting app NEVER brings it back
    deleteLoan(loan.id);
  }

  void cancelStageLoanDeletion(LoanModel loan) async {
    _stagedForDeletionIds.remove(loan.id);
    if (!_loans.any((l) => l.id == loan.id)) {
      _loans.add(loan);
      notifyListeners();
    }
    // Re-create in Firestore upon Undo
    try {
      await FirebaseFirestore.instance
          .collection('loans')
          .doc(loan.id)
          .set(loan.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error restoring loan to Firestore: $e");
    }
  }

  Future<void> confirmPermanentDelete(String loanId) async {
    _stagedForDeletionIds.remove(loanId);
    await deleteLoan(loanId);
  }

  Future<void> deleteLoan(String loanId) async {
    try {
      // 1. Delete loan document in Firestore immediately
      await FirebaseFirestore.instance.collection('loans').doc(loanId).delete();

      // 2. Delete all transactions in the sub-collection
      final txns = await FirebaseFirestore.instance
          .collection('loans')
          .doc(loanId)
          .collection('transactions')
          .get();
      for (final doc in txns.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Error purging loan document from Firestore: [REDACTED_ID]");
    }
  }

  @override
  void dispose() {
    _loansSubscription?.cancel();
    super.dispose();
  }
}
