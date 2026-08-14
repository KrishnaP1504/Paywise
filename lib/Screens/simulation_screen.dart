import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/models/loan_model.dart';

const List<String> _fullMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedLoanId; // store ID, not object reference

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = Provider.of<LoanProvider>(context);
    final activeLoans = loanProvider.loans.where((l) => !l.isPaidOff).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Always derive the selected loan from the LIVE list by ID
    if (activeLoans.isNotEmpty) {
      final ids = activeLoans.map((l) => l.id).toList();
      if (_selectedLoanId == null || !ids.contains(_selectedLoanId)) {
        _selectedLoanId = activeLoans.first.id;
      }
    }

    final selectedLoan = activeLoans.isEmpty
        ? null
        : activeLoans.firstWhere((l) => l.id == _selectedLoanId,
            orElse: () => activeLoans.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Loan Simulator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigo,
          indicatorWeight: 3,
          labelColor: isDark ? Colors.indigo[200] : Colors.indigo,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Extra EMI'),
            Tab(icon: Icon(Icons.savings_outlined), text: 'Lump Sum'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Refinancing'),
          ],
        ),
      ),
      body: activeLoans.isEmpty
          ? _buildNoLoans()
          : Column(
              children: [
                _buildLoanSelector(activeLoans, selectedLoan!, isDark),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ExtraEmiTab(loan: selectedLoan),
                      _LumpSumTab(loan: selectedLoan),
                      _RefinancingTab(loan: selectedLoan),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNoLoans() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calculate_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No active loans to simulate',
              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add a loan first from the Home tab',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLoanSelector(List<LoanModel> loans, LoanModel selectedLoan, bool isDark) {
    final softBg = isDark ? Colors.indigo.withValues(alpha: 0.2) : const Color(0xFFEEF0FD);

    return InkWell(
      onTap: () => _showLoanPickerBottomSheet(context, loans, isDark),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.indigo,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    selectedLoan.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${selectedLoan.interestRate}% interest · ${selectedLoan.tenureMonths}m · ₹${selectedLoan.emiAmount.toStringAsFixed(0)}/mo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: softBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.indigo,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoanPickerBottomSheet(
      BuildContext context, List<LoanModel> loans, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final sheetBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
        final borderCol = isDark ? const Color(0xFF2E324A) : const Color(0xFFE2E8F0);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Loan to Simulate",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF161C40),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Loan list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: loans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    final isSelected = loan.id == _selectedLoanId;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedLoanId = loan.id);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? Colors.indigo.withValues(alpha: 0.25)
                                  : const Color(0xFFEEF0FD))
                              : (isDark
                                  ? const Color(0xFF141624)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.indigo
                                : borderCol,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? Colors.indigo
                                  : (isDark ? Colors.grey[500] : Colors.grey[400]),
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loan.title,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF161C40),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${loan.interestRate}% rate · ${loan.tenureMonths} months · ₹${loan.emiAmount.toStringAsFixed(0)}/mo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${(loan.principalAmount / 1000).toStringAsFixed(0)}k',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.indigo
                                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── EXTRA EMI TAB ───────────────────────────
class _ExtraEmiTab extends StatefulWidget {
  final LoanModel loan;
  const _ExtraEmiTab({required this.loan});

  @override
  State<_ExtraEmiTab> createState() => _ExtraEmiTabState();
}

class _ExtraEmiTabState extends State<_ExtraEmiTab> {
  double _extraAmount = 1000;
  int _startingMonth = 1;

  late TextEditingController _extraCtrl;
  String? _extraError;

  @override
  void initState() {
    super.initState();
    _extraCtrl = TextEditingController(text: _extraAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ExtraEmiTab old) {
    super.didUpdateWidget(old);
    if (old.loan != widget.loan) {
      _extraAmount = 1000;
      _startingMonth = 1;
      _extraCtrl.text = '1000';
      _extraError = null;
    }
  }

  double get _maxExtra => widget.loan.emiAmount * 3;

  void _applyExtraFromText(String raw) {
    final val = double.tryParse(raw.replaceAll(',', ''));
    setState(() {
      if (val == null || val < 500) {
        _extraError = 'Minimum extra payment is ₹500';
        _extraAmount = 500;
        _extraCtrl.text = '500';
      } else if (val > _maxExtra) {
        _extraError = 'Max allowed is ₹${_maxExtra.toStringAsFixed(0)} (3× EMI)';
        _extraAmount = _maxExtra;
        _extraCtrl.text = _maxExtra.toStringAsFixed(0);
      } else {
        _extraError = null;
        _extraAmount = val;
      }
    });
  }

  Map<String, dynamic> _calculate() {
    final loan = widget.loan;
    double r = loan.interestRate / 12 / 100;
    int originalMonths = 0;
    double origInterest = 0;
    double bal = loan.outstandingBalance;

    while (bal > 0.01 && originalMonths < 1200) {
      double interest = bal * r;
      double principal = loan.emiAmount - interest;
      if (principal <= 0) break;
      if (principal > bal) principal = bal;
      origInterest += interest;
      bal -= principal;
      originalMonths++;
    }

    int newMonths = 0;
    double newInterest = 0;
    bal = loan.outstandingBalance;
    int month = 0;
    while (bal > 0.01 && newMonths < 1200) {
      month++;
      double interest = bal * r;
      double payment = loan.emiAmount;
      if (month >= _startingMonth) payment += _extraAmount;
      double principal = payment - interest;
      if (principal <= 0) break;
      if (principal > bal) principal = bal;
      newInterest += interest;
      bal -= principal;
      newMonths++;
    }

    return {
      'originalMonths': originalMonths,
      'newMonths': newMonths,
      'monthsSaved': originalMonths - newMonths,
      'interestSaved': origInterest - newInterest,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final result = _calculate();
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
    const accentColor = Colors.indigo;
    const successColor = Color(0xFF2E7D32);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        children: [
          _SimCard(
            icon: Icons.add_circle_outline,
            iconColor: accentColor,
            title: 'Extra Monthly Payment',
            subtitle: 'How much extra will you pay each month?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Extra Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _AmountField(
                  controller: _extraCtrl,
                  color: accentColor,
                  hint: 'e.g. 5000',
                  min: 500,
                  max: _maxExtra,
                  errorText: _extraError,
                  onSubmitted: _applyExtraFromText,
                ),
                Slider(
                  value: _extraAmount.clamp(500, _maxExtra),
                  min: 500,
                  max: _maxExtra,
                  divisions: ((_maxExtra - 500) / 500).round().clamp(1, 300),
                  activeColor: accentColor,
                  onChanged: (v) {
                    setState(() {
                      _extraAmount = v;
                      _extraError = null;
                      _extraCtrl.text = v.toStringAsFixed(0);
                    });
                  },
                ),
                _RangeHint(
                  min: '₹500 (min)',
                  max: '₹${_maxExtra.toStringAsFixed(0)} (3× EMI)',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Starting from Month', style: TextStyle(fontWeight: FontWeight.w600)),
                    _PillBadge(label: 'Month $_startingMonth', color: accentColor),
                  ],
                ),
                Slider(
                  value: _startingMonth.toDouble(),
                  min: 1,
                  max: loan.tenureMonths.toDouble(),
                  divisions: loan.tenureMonths - 1,
                  activeColor: accentColor,
                  onChanged: (v) => setState(() => _startingMonth = v.round()),
                ),
                _RangeHint(min: 'Month 1', max: 'Month ${loan.tenureMonths}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ResultCard(
            color: accentColor,
            results: [
              _ResultRow(label: 'Original Tenure', value: '${result['originalMonths']} months', icon: Icons.calendar_today),
              _ResultRow(label: 'New Tenure', value: '${result['newMonths']} months', icon: Icons.event_available, highlight: true, highlightColor: accentColor),
              _ResultRow(label: 'Time Saved', value: '${result['monthsSaved']} months', icon: Icons.timer, highlight: true, highlightColor: successColor),
              _ResultRow(label: 'Interest Saved', value: currency.format(result['interestSaved']), icon: Icons.savings, highlight: true, highlightColor: successColor),
            ],
          ),
          const SizedBox(height: 16),
          _InsightBanner(
            color: accentColor,
            icon: Icons.lightbulb_outline,
            text: 'Paying ${currency.format(_extraAmount)} extra from month $_startingMonth saves you '
                '${result['monthsSaved']} months and ${currency.format(result['interestSaved'])} in interest!',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── LUMP SUM TAB ───────────────────────────
enum LumpSumMode { single, annual, custom }

class CustomLumpSumEntry {
  int month;
  double amount;
  CustomLumpSumEntry({required this.month, required this.amount});
}

class _LumpSumTab extends StatefulWidget {
  final LoanModel loan;
  const _LumpSumTab({required this.loan});

  @override
  State<_LumpSumTab> createState() => _LumpSumTabState();
}

class _LumpSumTabState extends State<_LumpSumTab> {
  LumpSumMode _mode = LumpSumMode.annual;

  // Single Mode
  double _singleAmount = 50000;
  int _singleMonth = 6;
  late TextEditingController _singleCtrl;
  String? _singleError;

  // Annual Yearly Bonus Mode
  double _annualAmount = 50000;
  int _annualMonth = 5; // e.g. 5th month of each year
  late TextEditingController _annualCtrl;
  String? _annualError;

  // Custom Multiple Schedule Mode
  final List<CustomLumpSumEntry> _customEntries = [
    CustomLumpSumEntry(month: 12, amount: 50000),
  ];

  @override
  void initState() {
    super.initState();
    _singleCtrl = TextEditingController(text: _singleAmount.toStringAsFixed(0));
    _annualCtrl = TextEditingController(text: _annualAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _singleCtrl.dispose();
    _annualCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LumpSumTab old) {
    super.didUpdateWidget(old);
    if (old.loan != widget.loan) {
      _singleAmount = 50000;
      _singleMonth = 6;
      _singleCtrl.text = '50000';
      _singleError = null;

      _annualAmount = 50000;
      _annualMonth = 5;
      _annualCtrl.text = '50000';
      _annualError = null;
    }
  }

  double get _maxLump => widget.loan.outstandingBalance;

  void _applySingleFromText(String raw) {
    final val = double.tryParse(raw.replaceAll(',', ''));
    setState(() {
      if (val == null || val < 1000) {
        _singleError = 'Minimum lump sum is ₹1,000';
        _singleAmount = 1000;
        _singleCtrl.text = '1000';
      } else if (val > _maxLump) {
        _singleError = 'Cannot exceed outstanding balance (₹${_maxLump.toStringAsFixed(0)})';
        _singleAmount = _maxLump;
        _singleCtrl.text = _maxLump.toStringAsFixed(0);
      } else {
        _singleError = null;
        _singleAmount = val;
      }
    });
  }

  void _applyAnnualFromText(String raw) {
    final val = double.tryParse(raw.replaceAll(',', ''));
    setState(() {
      if (val == null || val < 1000) {
        _annualError = 'Minimum bonus is ₹1,000';
        _annualAmount = 1000;
        _annualCtrl.text = '1000';
      } else if (val > _maxLump) {
        _annualError = 'Cannot exceed balance (₹${_maxLump.toStringAsFixed(0)})';
        _annualAmount = _maxLump;
        _annualCtrl.text = _maxLump.toStringAsFixed(0);
      } else {
        _annualError = null;
        _annualAmount = val;
      }
    });
  }

  Map<String, dynamic> _calculate() {
    final loan = widget.loan;
    double r = loan.interestRate / 12 / 100;

    int origMonths = 0;
    double origInterest = 0;
    double bal = loan.outstandingBalance;
    while (bal > 0.01 && origMonths < 1200) {
      double interest = bal * r;
      double principal = loan.emiAmount - interest;
      if (principal <= 0) break;
      if (principal > bal) principal = bal;
      origInterest += interest;
      bal -= principal;
      origMonths++;
    }

    int newMonths = 0;
    double newInterest = 0;
    double totalLumpPaid = 0;
    bal = loan.outstandingBalance;
    int m = 0;

    while (bal > 0.01 && newMonths < 1200) {
      m++;
      newMonths++;
      double extraLump = 0;

      if (_mode == LumpSumMode.single) {
        if (m == _singleMonth) {
          extraLump = _singleAmount;
        }
      } else if (_mode == LumpSumMode.annual) {
        if (m >= _annualMonth && (m - _annualMonth) % 12 == 0) {
          extraLump = _annualAmount;
        }
      } else if (_mode == LumpSumMode.custom) {
        for (var entry in _customEntries) {
          if (entry.month == m) {
            extraLump += entry.amount;
          }
        }
      }

      if (extraLump > bal) extraLump = bal;

      double interest = bal * r;
      double principal = loan.emiAmount - interest;
      if (principal <= 0) break;

      bal = max(0, bal - extraLump);
      totalLumpPaid += extraLump;

      if (bal > 0) {
        if (principal > bal) principal = bal;
        bal -= principal;
      }
      newInterest += interest;
    }

    return {
      'originalMonths': origMonths,
      'newMonths': newMonths,
      'monthsSaved': max(0, origMonths - newMonths),
      'interestSaved': max(0.0, origInterest - newInterest),
      'totalLumpPaid': totalLumpPaid,
      'newBalance': bal,
    };
  }

  void _showAddCustomDialog() {
    int selectedMonth = 12;
    final amountCtrl = TextEditingController(text: '50000');

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add Custom Lump Sum"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Payment Amount (₹)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setDlgState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pay in Month $selectedMonth (Year ${(selectedMonth / 12).ceil()})"),
                      Slider(
                        value: selectedMonth.toDouble(),
                        min: 1,
                        max: widget.loan.tenureMonths.toDouble(),
                        divisions: max(1, widget.loan.tenureMonths - 1),
                        activeColor: Colors.indigo,
                        onChanged: (v) => setDlgState(() => selectedMonth = v.round()),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.replaceAll(',', ''));
                if (amt != null && amt >= 1000) {
                  setState(() {
                    _customEntries.add(CustomLumpSumEntry(month: selectedMonth, amount: amt));
                    _customEntries.sort((a, b) => a.month.compareTo(b.month));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add Payment"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final result = _calculate();
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
    const accentColor = Colors.indigo;
    const successColor = Color(0xFF2E7D32);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        children: [
          // ── MODE SELECTOR CARD ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFEEF0FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildModeBtn("One-Time", LumpSumMode.single),
                _buildModeBtn("Yearly Bonus", LumpSumMode.annual),
                _buildModeBtn("Custom Multi", LumpSumMode.custom),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── MODE CONTENT ──
          if (_mode == LumpSumMode.single) ...[
            _SimCard(
              icon: Icons.savings_outlined,
              iconColor: accentColor,
              title: 'One-Time Lump Sum Payment',
              subtitle: 'Simulate paying a single lump sum in a specific month',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _AmountField(
                    controller: _singleCtrl,
                    color: accentColor,
                    hint: 'e.g. 50000',
                    min: 1000,
                    max: _maxLump,
                    errorText: _singleError,
                    onSubmitted: _applySingleFromText,
                  ),
                  Slider(
                    value: _singleAmount.clamp(1000, _maxLump > 1000 ? _maxLump : 1001),
                    min: 1000,
                    max: _maxLump > 1000 ? _maxLump : 1001,
                    divisions: ((_maxLump - 1000) / 1000).round().clamp(1, 500),
                    activeColor: accentColor,
                    onChanged: (v) {
                      setState(() {
                        _singleAmount = v;
                        _singleError = null;
                        _singleCtrl.text = v.toStringAsFixed(0);
                      });
                    },
                  ),
                  _RangeHint(
                    min: '₹1,000 (min)',
                    max: '₹${_maxLump.toStringAsFixed(0)} (full balance)',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment in Month', style: TextStyle(fontWeight: FontWeight.w600)),
                      _PillBadge(label: 'Month $_singleMonth (Yr ${(_singleMonth / 12).ceil()})', color: accentColor),
                    ],
                  ),
                  Slider(
                    value: _singleMonth.toDouble(),
                    min: 1,
                    max: loan.tenureMonths.toDouble(),
                    divisions: max(1, loan.tenureMonths - 1),
                    activeColor: accentColor,
                    onChanged: (v) => setState(() => _singleMonth = v.round()),
                  ),
                  _RangeHint(min: 'Month 1', max: 'Month ${loan.tenureMonths}'),
                ],
              ),
            ),
          ] else if (_mode == LumpSumMode.annual) ...[
            _SimCard(
              icon: Icons.card_giftcard_rounded,
              iconColor: accentColor,
              title: 'Recurring Annual Yearly Bonus',
              subtitle: 'Simulate paying extra from your bonus every year',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Annual Bonus Prepayment Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _AmountField(
                    controller: _annualCtrl,
                    color: accentColor,
                    hint: 'e.g. 50000',
                    min: 1000,
                    max: _maxLump,
                    errorText: _annualError,
                    onSubmitted: _applyAnnualFromText,
                  ),
                  Slider(
                    value: _annualAmount.clamp(1000, _maxLump > 1000 ? _maxLump : 1001),
                    min: 1000,
                    max: _maxLump > 1000 ? _maxLump : 1001,
                    divisions: ((_maxLump - 1000) / 1000).round().clamp(1, 500),
                    activeColor: accentColor,
                    onChanged: (v) {
                      setState(() {
                        _annualAmount = v;
                        _annualError = null;
                        _annualCtrl.text = v.toStringAsFixed(0);
                      });
                    },
                  ),
                  _RangeHint(
                    min: '₹1,000 (min)',
                    max: '₹${_maxLump.toStringAsFixed(0)} (max)',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bonus Month Each Year', style: TextStyle(fontWeight: FontWeight.w600)),
                      _PillBadge(
                        label: 'Month $_annualMonth of each year',
                        color: accentColor,
                      ),
                    ],
                  ),
                  Slider(
                    value: _annualMonth.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    activeColor: accentColor,
                    onChanged: (v) => setState(() => _annualMonth = v.round()),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Selected: ${_fullMonthNames[_annualMonth - 1]} (Month $_annualMonth)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _SimCard(
              icon: Icons.playlist_add_rounded,
              iconColor: accentColor,
              title: 'Custom Multiple Prepayments',
              subtitle: 'Add custom lump sum payments for specific months',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── INFORMATIVE EXPLANATION BANNER ──
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2442) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.indigo, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Schedule custom lump sum extra payments for specific months (e.g. Year 1 Month 12 bonus, Year 2 Month 18 bonus). Each payment reduces your principal directly, saving interest & shortening tenure!",
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: isDark ? const Color(0xFFC0C7E5) : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${_customEntries.length} Payments Configured",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddCustomDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Add"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_customEntries.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("No custom lump sum payments added yet.", style: TextStyle(color: Colors.grey[500])),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = _customEntries[index];
                        final year = (entry.month / 12).ceil();

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF141624) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF2E324A) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.stars_rounded, color: Colors.indigo, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Month ${entry.month} (Year $year)",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      "Extra ${currency.format(entry.amount)} + Regular EMI",
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() => _customEntries.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── RESULTS CARD ──
          _ResultCard(
            color: accentColor,
            results: [
              _ResultRow(
                label: 'Total Extra Lump Paid',
                value: currency.format(result['totalLumpPaid']),
                icon: Icons.payments_outlined,
                highlight: true,
                highlightColor: accentColor,
              ),
              _ResultRow(
                label: 'Original Tenure',
                value: '${result['originalMonths']} months',
                icon: Icons.calendar_today,
              ),
              _ResultRow(
                label: 'New Tenure',
                value: '${result['newMonths']} months (${(result['newMonths'] / 12).toStringAsFixed(1)} yrs)',
                icon: Icons.event_available,
                highlight: true,
                highlightColor: accentColor,
              ),
              _ResultRow(
                label: 'Months Saved',
                value: '${result['monthsSaved']} months',
                icon: Icons.timer,
                highlight: true,
                highlightColor: successColor,
              ),
              _ResultRow(
                label: 'Interest Saved',
                value: currency.format(result['interestSaved']),
                icon: Icons.savings,
                highlight: true,
                highlightColor: successColor,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── INSIGHT BANNER ──
          _InsightBanner(
            color: accentColor,
            icon: Icons.celebration_outlined,
            text: _mode == LumpSumMode.annual
                ? 'Paying ${currency.format(_annualAmount)} annual bonus in Month $_annualMonth of each year saves you '
                    '${result['monthsSaved']} months and ${currency.format(result['interestSaved'])} in interest!'
                : _mode == LumpSumMode.custom
                    ? 'Your ${_customEntries.length} custom lump sum prepayments save '
                        '${result['monthsSaved']} months and ${currency.format(result['interestSaved'])} in interest!'
                    : 'Paying ${currency.format(_singleAmount)} lump sum in Month $_singleMonth closes your loan '
                        '${result['monthsSaved']} months earlier and saves ${currency.format(result['interestSaved'])}!',
          ),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String title, LumpSumMode mode) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.indigo,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── REFINANCING TAB ───────────────────────────
class _RefinancingTab extends StatefulWidget {
  final LoanModel loan;
  const _RefinancingTab({required this.loan});

  @override
  State<_RefinancingTab> createState() => _RefinancingTabState();
}

class _RefinancingTabState extends State<_RefinancingTab> {
  late double _newRate;

  late TextEditingController _rateCtrl;
  String? _rateError;

  @override
  void initState() {
    super.initState();
    _newRate = max(1.0, widget.loan.interestRate - 1.0);
    _rateCtrl = TextEditingController(text: _newRate.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_RefinancingTab old) {
    super.didUpdateWidget(old);
    if (old.loan != widget.loan) {
      _newRate = max(1.0, widget.loan.interestRate - 1.0);
      _rateCtrl.text = _newRate.toStringAsFixed(2);
      _rateError = null;
    }
  }

  double get _minRate => 1.0;
  double get _maxRate => widget.loan.interestRate > 1 ? widget.loan.interestRate - 0.01 : 1.99;

  void _applyRateFromText(String raw) {
    final val = double.tryParse(raw);
    setState(() {
      if (val == null || val < _minRate) {
        _rateError = 'Minimum rate is 1.00%';
        _newRate = _minRate;
        _rateCtrl.text = _minRate.toStringAsFixed(2);
      } else if (val >= widget.loan.interestRate) {
        _rateError = 'New rate must be lower than current (${widget.loan.interestRate}%)';
        _newRate = _maxRate;
        _rateCtrl.text = _maxRate.toStringAsFixed(2);
      } else {
        _rateError = null;
        _newRate = val;
      }
    });
  }

  double _calcEmi(double principal, double rate, int months) {
    if (rate == 0) return principal / months;
    double r = rate / 12 / 100;
    return (principal * r * pow(1 + r, months)) / (pow(1 + r, months) - 1);
  }

  Map<String, dynamic> _calculate() {
    final loan = widget.loan;
    double bal = loan.outstandingBalance;
    int remainingMonths = loan.tenureMonths -
        ((loan.totalPaid / loan.emiAmount).floor().clamp(0, loan.tenureMonths));
    if (remainingMonths < 1) remainingMonths = 1;

    double origEmi = loan.emiAmount;
    double origTotalInterest = 0;
    double b = bal;
    double r0 = loan.interestRate / 12 / 100;
    for (int i = 0; i < remainingMonths; i++) {
      double interest = b * r0;
      double principal = origEmi - interest;
      if (principal > b) principal = b;
      origTotalInterest += interest;
      b -= principal;
      if (b < 0.01) break;
    }

    double newEmi = _calcEmi(bal, _newRate, remainingMonths);
    double newTotalInterest = 0;
    b = bal;
    double r1 = _newRate / 12 / 100;
    for (int i = 0; i < remainingMonths; i++) {
      double interest = b * r1;
      double principal = newEmi - interest;
      if (principal > b) principal = b;
      newTotalInterest += interest;
      b -= principal;
      if (b < 0.01) break;
    }

    return {
      'originalEmi': origEmi,
      'newEmi': newEmi,
      'emiSaving': origEmi - newEmi,
      'interestSaved': origTotalInterest - newTotalInterest,
      'remainingMonths': remainingMonths,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final result = _calculate();
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
    final saving = result['emiSaving'] as double;
    const accentColor = Colors.indigo;
    const successColor = Color(0xFF2E7D32);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      child: Column(
        children: [
          _SimCard(
            icon: Icons.swap_horiz,
            iconColor: accentColor,
            title: 'Refinancing Simulator',
            subtitle: 'What if you switch to a lower interest rate?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _RateBox(label: 'Current Rate', value: '${loan.interestRate}%', color: const Color(0xFFFFEBEE), textColor: const Color(0xFFC62828))),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(child: _RateBox(label: 'New Rate', value: '${_newRate.toStringAsFixed(2)}%', color: const Color(0xFFE8F5E9), textColor: successColor)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('New Interest Rate (%)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _AmountField(
                  controller: _rateCtrl,
                  color: accentColor,
                  hint: 'e.g. 7.5',
                  min: _minRate,
                  max: _maxRate,
                  errorText: _rateError,
                  isDecimal: true,
                  suffix: '%',
                  onSubmitted: _applyRateFromText,
                ),
                Slider(
                  value: _newRate.clamp(_minRate, _maxRate),
                  min: _minRate,
                  max: _maxRate,
                  divisions: ((_maxRate - _minRate) * 10).round().clamp(1, 200),
                  activeColor: accentColor,
                  onChanged: (v) {
                    setState(() {
                      _newRate = v;
                      _rateError = null;
                      _rateCtrl.text = v.toStringAsFixed(2);
                    });
                  },
                ),
                _RangeHint(min: '${_minRate.toStringAsFixed(1)}% (min)', max: '${_maxRate.toStringAsFixed(2)}% (just below current)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ResultCard(
            color: accentColor,
            results: [
              _ResultRow(label: 'Current EMI', value: currency.format(result['originalEmi']), icon: Icons.payment),
              _ResultRow(label: 'New EMI', value: currency.format(result['newEmi']), icon: Icons.arrow_downward, highlight: true, highlightColor: accentColor),
              _ResultRow(label: 'Monthly Saving', value: currency.format(saving), icon: Icons.trending_down, highlight: saving > 0, highlightColor: successColor),
              _ResultRow(label: 'Total Interest Saved', value: currency.format(result['interestSaved']), icon: Icons.savings, highlight: true, highlightColor: successColor),
            ],
          ),
          const SizedBox(height: 16),
          _InsightBanner(
            color: accentColor,
            icon: Icons.trending_down,
            text: 'Refinancing from ${loan.interestRate}% to ${_newRate.toStringAsFixed(2)}% saves you '
                '${currency.format(saving)} every month — '
                '${currency.format(result['interestSaved'])} over the remaining tenure!',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── SHARED WIDGETS ───────────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final String hint;
  final double min;
  final double max;
  final String? errorText;
  final bool isDecimal;
  final String? suffix;
  final void Function(String) onSubmitted;

  const _AmountField({
    required this.controller,
    required this.color,
    required this.hint,
    required this.min,
    required this.max,
    required this.errorText,
    required this.onSubmitted,
    this.isDecimal = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: isDecimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            prefixText: suffix == null ? '₹ ' : null,
            suffixText: suffix,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            errorText: errorText,
            errorMaxLines: 2,
          ),
          onSubmitted: onSubmitted,
          onEditingComplete: () {
            onSubmitted(controller.text);
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }
}

class _RangeHint extends StatelessWidget {
  final String min;
  final String max;
  const _RangeHint({required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.grey[300]! : const Color(0xFF424242);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(min, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
          Text(max, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hintColor)),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.indigo.withValues(alpha: 0.25) : const Color(0xFFEEF0FD);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _SimCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _SimCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softIconBg = isDark ? Colors.indigo.withValues(alpha: 0.25) : const Color(0xFFEEF0FD);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: softIconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Color color;
  final List<_ResultRow> results;

  const _ResultCard({required this.color, required this.results});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              const Text('Simulation Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...results.map((r) => _buildRow(r, isDark)),
        ],
      ),
    );
  }

  Widget _buildRow(_ResultRow r, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(r.icon, size: 18,
              color: r.highlight ? r.highlightColor : (isDark ? Colors.grey[400] : Colors.grey[500])),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.label,
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 13)),
          ),
          Text(
            r.value,
            style: TextStyle(
              fontWeight: r.highlight ? FontWeight.bold : FontWeight.w600,
              fontSize: r.highlight ? 15 : 14,
              color: r.highlight ? r.highlightColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final Color highlightColor;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.highlightColor = const Color(0xFF2E7D32),
  });
}

class _InsightBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InsightBanner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.indigo.withValues(alpha: 0.2) : const Color(0xFFEEF0FD);
    final textColor = isDark ? Colors.indigo[100]! : Colors.indigo[900]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.indigo, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(color: textColor, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _RateBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _RateBox({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}
