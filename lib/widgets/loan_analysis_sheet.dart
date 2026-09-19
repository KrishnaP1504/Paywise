import 'package:flutter/material.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/Screens/loan_analysis_screen.dart';

export 'package:paywise/Screens/loan_analysis_screen.dart';

/// Opens the dedicated full Loan Analysis page for the given [loan].
void showLoanPeriodAnalysis(BuildContext context, LoanModel loan) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LoanAnalysisScreen(loan: loan),
    ),
  );
}
