class TransactionModel {
  final String id;
  final String loanId;
  final double amount;
  final DateTime date;
  final String type; // 'EMI' or 'Prepayment'

  TransactionModel({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.type = 'EMI',
  });

  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TransactionModel(
      id: docId,
      loanId: map['loanId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      type: map['type'] ?? 'EMI',
    );
  }
}
