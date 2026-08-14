class LoanModel {
  final String id;
  final String userId;
  final String title;
  final String lenderName;
  final double principalAmount;
  final double interestRate;
  final int tenureMonths;
  final DateTime startDate;
  final int emiDueDate;
  double emiAmount;
  double totalInterest;
  double totalPayable;
  
  // Ledger Fields
  double outstandingBalance; 
  double totalPaid;
  bool isPaidOff;
  final String category; 

  LoanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.lenderName,
    required this.principalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.startDate,
    required this.emiDueDate,
    this.emiAmount = 0.0,
    this.totalInterest = 0.0,
    this.totalPayable = 0.0,
    this.outstandingBalance = 0.0,
    this.totalPaid = 0.0,
    this.isPaidOff = false,
    this.category = 'Personal',
  });

  // Helper for Calendar
  int get paymentsMade {
    if (totalPaid > 0 && emiAmount > 0) {
      return (totalPaid / emiAmount).floor();
    }
    return 0; 
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'lenderName': lenderName,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'startDate': startDate.toIso8601String(),
      'emiDueDate': emiDueDate,
      'emiAmount': emiAmount,
      'totalInterest': totalInterest,
      'totalPayable': totalPayable,
      'outstandingBalance': outstandingBalance,
      'totalPaid': totalPaid,
      'isPaidOff': isPaidOff,
      'category': category,
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map, String docId) {
    double principal = (map['principalAmount'] ?? 0).toDouble();
    
    return LoanModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      lenderName: map['lenderName'] ?? '',
      principalAmount: principal,
      interestRate: (map['interestRate'] ?? 0).toDouble(),
      tenureMonths: map['tenureMonths'] ?? 0,
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      emiDueDate: map['emiDueDate'] ?? 1,
      emiAmount: (map['emiAmount'] ?? 0).toDouble(),
      totalInterest: (map['totalInterest'] ?? 0).toDouble(),
      totalPayable: (map['totalPayable'] ?? 0).toDouble(),
      outstandingBalance: (map['outstandingBalance'] ?? principal).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0).toDouble(),
      isPaidOff: map['isPaidOff'] ?? false,
      category: map['category'] ?? 'Personal',
    );
  }
}

// Required for PDF Generation
class AmortizationRow {
  final int month;
  final double emi;
  final double principalComponent;
  final double interestComponent;
  final double closingBalance;

  AmortizationRow(
    this.month, 
    this.emi, 
    this.principalComponent, 
    this.interestComponent, 
    this.closingBalance
  );
}
