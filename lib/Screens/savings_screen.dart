import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paywise/models/loan_model.dart';

class SavingsScreen extends StatefulWidget {
  final LoanModel loan;

  const SavingsScreen({super.key, required this.loan});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  double _extraEMI = 0;
  double _sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
    
    // 1. CALCULATE BASE SCENARIO (Current Path)
    double balance = widget.loan.outstandingBalance;
    double rate = widget.loan.interestRate / 12 / 100;
    double currentEMI = widget.loan.emiAmount;
    
    int remainingMonths = 0;
    double totalRemainingInterest = 0;
    
    if (balance > 0 && rate > 0 && currentEMI > 0) {
      if (balance * rate < currentEMI) {
         double n = -log(1 - (rate * balance) / currentEMI) / log(1 + rate);
         remainingMonths = n.ceil();
         totalRemainingInterest = (remainingMonths * currentEMI) - balance;
      }
    }

    // 2. CALCULATE NEW SCENARIO (With Extra Payment)
    double newEMI = currentEMI + _extraEMI;
    int newMonths = 0;
    double newTotalInterest = 0;
    
    if (balance > 0 && rate > 0 && newEMI > 0) {
       if (balance * rate < newEMI) {
         double n = -log(1 - (rate * balance) / newEMI) / log(1 + rate);
         newMonths = n.ceil();
         newTotalInterest = (newMonths * newEMI) - balance;
       }
    }

    // 3. SAVINGS
    double interestSaved = totalRemainingInterest - newTotalInterest;
    int timeSaved = remainingMonths - newMonths;
    if (interestSaved < 0) interestSaved = 0;
    if (timeSaved < 0) timeSaved = 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Savings Simulator")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("If you pay extra...", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text(
                    "+ ${currency.format(_extraEMI)} / month",
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text("Total Monthly: ${currency.format(newEMI)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // SLIDER INPUT
            const Text("Adjust Extra Amount", style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _sliderValue,
              min: 0,
              max: widget.loan.emiAmount * 2, 
              divisions: 20,
              activeColor: Colors.green,
              label: currency.format(_sliderValue),
              onChanged: (val) {
                setState(() {
                  _sliderValue = val;
                  _extraEMI = val;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("₹0"),
                Text(currency.format(widget.loan.emiAmount * 2)),
              ],
            ),
            
            const SizedBox(height: 30),

            // RESULTS GRID
            Row(
              children: [
                _resultCard(
                  "Money Saved", 
                  currency.format(interestSaved), 
                  Icons.savings, 
                  Colors.green
                ),
                const SizedBox(width: 15),
                _resultCard(
                  "Time Saved", 
                  "$timeSaved Months", 
                  Icons.timelapse, 
                  Colors.blue
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // SUMMARY TEXT
            if (_extraEMI > 0)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  // FIXED: Replaced withOpacity with withValues
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green)
                ),
                child: Text(
                  "By paying just ${currency.format(_extraEMI)} extra, you could finish your loan $timeSaved months early and save ${currency.format(interestSaved)}!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              )
            else
               const Text("Move the slider to see your savings!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // FIXED: Replaced withOpacity with withValues
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)]
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          ],
        ),
      ),
    );
  }
}
