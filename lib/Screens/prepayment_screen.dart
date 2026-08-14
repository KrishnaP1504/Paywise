import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paywise/models/loan_model.dart';

class PrepaymentScreen extends StatefulWidget {
  const PrepaymentScreen({super.key});

  @override
  State<PrepaymentScreen> createState() => _PrepaymentScreenState();
}

class _PrepaymentScreenState extends State<PrepaymentScreen> {
  final _extraController = TextEditingController();
  
  // Results
  double? _originalInterest;
  double? _newInterest;
  double? _savings;
  int? _monthsSaved;
  int? _newTenure;

  void _calculateImpact(LoanModel loan) {
    if (_extraController.text.isEmpty) return;
    double extraPerMonth = double.tryParse(_extraController.text) ?? 0;
    if (extraPerMonth < 0) return;

    // 1. ORIGINAL SCENARIO
    double rate = loan.interestRate / 12 / 100;
    double emi = loan.emiAmount;
    
    // Original Total Interest (if user just pays EMI)
    double totalOriginalPayable = emi * loan.tenureMonths;
    double originalTotalInt = totalOriginalPayable - loan.principalAmount;

    // 2. NEW SCENARIO (Iterative Calculation)
    double balance = loan.principalAmount;
    double totalNewInterest = 0;
    int months = 0;
    double monthlyPay = emi + extraPerMonth;

    // Loop until paid off
    while (balance > 0 && months < 360) { // Safety cap at 30 years
      months++;
      double interestForMonth = balance * rate;
      double principalForMonth = monthlyPay - interestForMonth;
      
      totalNewInterest += interestForMonth;
      balance -= principalForMonth;
    }

    // 3. RESULTS
    setState(() {
      _originalInterest = originalTotalInt;
      _newInterest = totalNewInterest;
      _savings = originalTotalInt - totalNewInterest;
      _newTenure = months;
      _monthsSaved = loan.tenureMonths - months;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loan = ModalRoute.of(context)!.settings.arguments as LoanModel;
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Prepayment Simulator")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Loan: ${loan.title}", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 5),
            Text("Current EMI: ${currency.format(loan.emiAmount)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 30),
            
            // Input Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("How much EXTRA can you pay monthly?", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _extraController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "₹ ",
                        labelText: "Extra Amount",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50]
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus(); // Hide keyboard
                          _calculateImpact(loan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15)
                        ),
                        child: const Text("ANALYZE SAVINGS"),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Results Section
            if (_savings != null) ...[
              const SizedBox(height: 30),
              const Text(" Analysis Report", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              // Big Green Savings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      // FIXED: Deprecated withOpacity replaced
                      color: Colors.green.withValues(alpha: 0.3), 
                      blurRadius: 10, 
                      offset: const Offset(0,5)
                    )
                  ]
                ),
                child: Column(
                  children: [
                    const Text("TOTAL SAVINGS", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                    const SizedBox(height: 5),
                    Text(currency.format(_savings), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text("Debt-free $_monthsSaved months earlier!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Comparison Grid
              Row(
                children: [
                  Expanded(child: _resultBox("New Tenure", "$_newTenure Months", Colors.blue[50]!, Colors.blue)),
                  const SizedBox(width: 15),
                  Expanded(child: _resultBox("New Interest", currency.format(_newInterest), Colors.orange[50]!, Colors.orange)),
                ],
              ),
              const SizedBox(height: 15),
              // ADDED: Display Original Interest to use the variable
              Row(
                children: [
                  Expanded(child: _resultBox("Original Interest", currency.format(_originalInterest), Colors.grey[200]!, Colors.grey[700]!)),
                ],
              ),
              const SizedBox(height: 30),
            ]
          ],
        ),
      ),
    );
  }

  Widget _resultBox(String label, String value, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        // FIXED: Deprecated withOpacity replaced
        border: Border.all(color: text.withValues(alpha: 0.3))
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: text, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
