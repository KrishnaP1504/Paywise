import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/notification_service.dart';
import 'package:paywise/widgets/undo_toast.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _lenderController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _dateController = TextEditingController();

  double? _previewEMI;
  double? _previewTotalInterest;
  bool _isSaving = false;
  int _selectedDay = 5;

  String _selectedCategory = 'Personal';
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Personal', 'icon': Icons.person},
    {'name': 'Home', 'icon': Icons.home_rounded},
    {'name': 'Car', 'icon': Icons.directions_car_rounded},
    {'name': 'Education', 'icon': Icons.school_rounded},
    {'name': 'Business', 'icon': Icons.store_rounded},
    {'name': 'Two-Wheeler', 'icon': Icons.two_wheeler_rounded},
    {'name': 'Gold', 'icon': Icons.monetization_on_rounded},
  ];

  static const List<String> _indianBanks = [
    // Public Sector Banks (12)
    'State Bank of India (SBI)',
    'Bank of Baroda',
    'Bank of India',
    'Bank of Maharashtra',
    'Canara Bank',
    'Central Bank of India',
    'Indian Bank',
    'Indian Overseas Bank',
    'Punjab National Bank (PNB)',
    'Punjab & Sind Bank',
    'Union Bank of India',
    'UCO Bank',

    // Private Sector Banks (21)
    'Axis Bank',
    'Bandhan Bank',
    'CSB Bank',
    'City Union Bank',
    'DCB Bank',
    'Dhanlaxmi Bank',
    'Federal Bank',
    'HDFC Bank',
    'ICICI Bank',
    'IDBI Bank',
    'IDFC FIRST Bank',
    'IndusInd Bank',
    'Jammu & Kashmir Bank',
    'Karnataka Bank',
    'Karur Vysya Bank',
    'Kotak Mahindra Bank',
    'Nainital Bank',
    'RBL Bank',
    'South Indian Bank',
    'Tamilnad Mercantile Bank',
    'Yes Bank',

    // Popular Housing Finance & NBFCs
    'Bajaj Finserv',
    'Tata Capital',
    'LIC Housing Finance',
    'PNB Housing Finance',
    'Muthoot Finance',
    'Manappuram Finance',
    'L&T Finance',
    'Aditya Birla Capital',
    'Cholamandalam Investment',
    'Mahindra Finance',
  ];

  int _getMaxTenureMonths(String category) {
    switch (category) {
      case 'Home':
        return 360; // 30 Years (360 Months)
      case 'Business':
        return 240; // 20 Years (240 Months - LAP / Business)
      case 'Education':
        return 180; // 15 Years (180 Months)
      case 'Car':
        return 96; // 8 Years (84-96 Months - Car / Auto)
      case 'Personal':
        return 84; // 7 Years (84 Months)
      case 'Two-Wheeler':
        return 60; // 5 Years (60 Months)
      case 'Gold':
        return 36; // 3 Years (36 Months)
      default:
        return 360;
    }
  }

  bool get _isRateExceeded {
    final val = _rateController.text.trim();
    if (val.isEmpty) return false;
    final rate = double.tryParse(val);
    if (rate == null) return false;
    return rate > 50.0;
  }

  bool get _isTenureExceeded {
    final val = _tenureController.text.trim();
    if (val.isEmpty) return false;
    final months = int.tryParse(val);
    if (months == null) return false;
    final maxM = _getMaxTenureMonths(_selectedCategory);
    return months > maxM;
  }

  bool get _isFormValid {
    final lender = _lenderController.text.trim();
    final amountStr = _amountController.text.trim();
    final rateStr = _rateController.text.trim();
    final tenureStr = _tenureController.text.trim();

    if (lender.isEmpty) return false;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return false;

    final rate = double.tryParse(rateStr);
    if (rate == null || rate <= 0 || rate > 50.0) return false;

    final tenure = int.tryParse(tenureStr);
    if (tenure == null || tenure <= 0 || tenure > _getMaxTenureMonths(_selectedCategory)) return false;

    return true;
  }

  final FocusNode _lenderFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _dateController.text = "Day $_selectedDay of every month";
    _lenderFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lenderController.dispose();
    _lenderFocusNode.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Widget _buildLenderBankSuggestions(Color textDark, bool isDark) {
    final query = _lenderController.text.trim().toLowerCase();
    if (query.isEmpty || !_lenderFocusNode.hasFocus) {
      return const SizedBox.shrink();
    }

    final matches = _indianBanks
        .where((b) => b.toLowerCase().contains(query))
        .take(5)
        .toList();

    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: matches.map((bank) {
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.account_balance_rounded, size: 18, color: Color(0xFF3B4CCA)),
            title: Text(
              bank,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: textDark,
              ),
            ),
            onTap: () {
              _lenderController.text = bank;
              _lenderFocusNode.unfocus();
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }

  void _calculatePreview() {
    if (_amountController.text.isEmpty ||
        _rateController.text.isEmpty ||
        _tenureController.text.isEmpty) {
      return;
    }

    double p = double.tryParse(_amountController.text) ?? 0;
    double r = (double.tryParse(_rateController.text) ?? 0) / 12 / 100;
    double n = double.tryParse(_tenureController.text) ?? 0;

    if (p > 0 && r > 0 && n > 0) {
      double emi = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
      setState(() {
        _previewEMI = emi;
        _previewTotalInterest = (emi * n) - p;
      });
    }
  }

  Future<void> _pickEmiDay() async {
    int? picked = await showDialog<int>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Select EMI Due Day",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (context, index) {
                int day = index + 1;
                final isSelected = day == _selectedDay;
                return ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tileColor: isSelected
                      ? const Color(0xFF3B4CCA).withValues(alpha: 0.1)
                      : Colors.transparent,
                  title: Text(
                    "Day $day of every month",
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF3B4CCA) : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF3B4CCA))
                      : null,
                  onTap: () => Navigator.pop(context, day),
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _dateController.text = "Day $_selectedDay of every month";
      });
    }
  }

  Future<void> _saveLoan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ERROR: Not logged in!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String generatedTitle = "$_selectedCategory Loan";
    String cleanLender = _lenderController.text.trim().toUpperCase();

    final loan = LoanModel(
      id: '',
      userId: user.uid,
      title: generatedTitle,
      lenderName: cleanLender,
      principalAmount: double.parse(_amountController.text),
      interestRate: double.parse(_rateController.text),
      tenureMonths: int.parse(_tenureController.text),
      startDate: DateTime.now(),
      emiDueDate: _selectedDay,
      emiAmount: _previewEMI ?? 0,
      totalInterest: _previewTotalInterest ?? 0,
      totalPayable: (_previewEMI ?? 0) * int.parse(_tenureController.text),
      category: _selectedCategory,
    );

    try {
      String loanId =
          await Provider.of<LoanProvider>(context, listen: false).addLoan(loan);

      try {
        await NotificationService().scheduleAll5EmiReminders(
          loanId: loanId,
          loanTitle: generatedTitle,
          emiAmount: _previewEMI ?? 0,
          dueDayOfMonth: _selectedDay,
        );
      } catch (e) {
        debugPrint("Notification Warning: $e");
      }

      if (mounted) {
        Navigator.pop(context);
        UndoToastManager.showSuccessToast(
          context: context,
          title: "$generatedTitle saved successfully",
          subtitle: "Your loan details have been added.",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0F1B) : const Color(0xFFF7F8FE);
    final cardBgColor = isDark ? const Color(0xFF16192A) : Colors.white;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFFA0A7C2) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF1E2238) : const Color(0xFFFAFAFE);
    final inputBorder = isDark ? const Color(0xFF2E3452) : const Color(0xFFE2E8F0);
    const primaryIndigo = Color(0xFF3B4CCA);
    final iconBoxBg = isDark ? primaryIndigo.withValues(alpha: 0.2) : const Color(0xFFEEF2FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              // ── 1. TOP APP BAR & GRAPHIC HEADER ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Back Button matching Target Screenshot
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title + 3D Wallet Graphic Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add New Loan",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Enter your loan details to get started",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: textSub,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: 3D Blue Wallet Graphic Container
                  SizedBox(
                    width: 100,
                    height: 85,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft glowing aura
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryIndigo.withValues(alpha: 0.08),
                          ),
                        ),
                        // 3D Wallet / Logo Graphic
                        Image.asset(
                          'assets/images/paywise_logo.png',
                          width: 75,
                          height: 75,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2A36B1), Color(0xFF4C5BE3)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── 2. FORM CARD CONTAINER ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── FIELD 1: LOAN CATEGORY ──
                      _buildFieldLabel("Loan Category", textDark),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['name'],
                                child: Row(
                                  children: [
                                    _buildIconBox(
                                      iconBoxBg,
                                      Icon(cat['icon'], color: primaryIndigo, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      cat['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── FIELD 2: LENDER NAME (AUTOCOMPLETE) ──
                      _buildFieldLabel("Lender / Bank Name", textDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _lenderController,
                        focusNode: _lenderFocusNode,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        decoration: _buildInputDecoration(
                          hint: "Type to search (e.g. HDFC, SBI, Axis)",
                          iconBoxBg: iconBoxBg,
                          icon: const Icon(
                            Icons.museum_outlined,
                            color: primaryIndigo,
                            size: 20,
                          ),
                          inputBg: inputBg,
                          inputBorder: inputBorder,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      _buildLenderBankSuggestions(textDark, isDark),

                      const SizedBox(height: 18),

                      // ── FIELD 3: EMI PAYMENT DATE ──
                      _buildFieldLabel("EMI Payment Date", textDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _pickEmiDay,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        decoration: _buildInputDecoration(
                          hint: "Day 5 of every month",
                          iconBoxBg: iconBoxBg,
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            color: primaryIndigo,
                            size: 20,
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF1E293B),
                            size: 18,
                          ),
                          inputBg: inputBg,
                          inputBorder: inputBorder,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── FIELD 4 & 5: AMOUNT & RATE OF INTEREST (%) ROW ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount Field
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel("Amount", textDark),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Enter amount",
                                    iconBoxBg: iconBoxBg,
                                    customPrefixWidget: const Text(
                                      "₹",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                    inputBg: inputBg,
                                    inputBorder: inputBorder,
                                  ),
                                  onChanged: (_) {
                                    setState(() {});
                                    _calculatePreview();
                                  },
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    final amt = double.tryParse(val.trim());
                                    if (amt == null || amt <= 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Rate of Interest (%) Field
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel("Rate of Interest (%)", textDark),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _rateController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hint: "Max 50%",
                                    iconBoxBg: iconBoxBg,
                                    customPrefixWidget: const Text(
                                      "%",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryIndigo,
                                      ),
                                    ),
                                    inputBg: inputBg,
                                    inputBorder: inputBorder,
                                  ),
                                  onChanged: (_) {
                                    setState(() {});
                                    _calculatePreview();
                                  },
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    final r = double.tryParse(val.trim());
                                    if (r == null || r <= 0) return 'Invalid';
                                    if (r > 50.0) return 'Max interest rate is 50%';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isRateExceeded) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Not possible: Maximum Rate of Interest allowed is 50%",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ── FIELD 6: TENURE (MONTHS) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel("Tenure (Months)", textDark),
                          Text(
                            "Max: ${_getMaxTenureMonths(_selectedCategory)} Mo (${_getMaxTenureMonths(_selectedCategory) ~/ 12} Yrs)",
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: primaryIndigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tenureController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                        decoration: _buildInputDecoration(
                          hint: "Max ${_getMaxTenureMonths(_selectedCategory)} months",
                          iconBoxBg: iconBoxBg,
                          icon: const Icon(
                            Icons.access_time_rounded,
                            color: primaryIndigo,
                            size: 20,
                          ),
                          inputBg: inputBg,
                          inputBorder: inputBorder,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _calculatePreview();
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final months = int.tryParse(val.trim());
                          if (months == null || months <= 0) return 'Invalid';
                          final maxM = _getMaxTenureMonths(_selectedCategory);
                          if (months > maxM) {
                            final maxY = maxM ~/ 12;
                            return 'Not possible: Max for $_selectedCategory loan is $maxM months ($maxY yrs)';
                          }
                          return null;
                        },
                      ),
                      if (_isTenureExceeded) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Not possible: Maximum tenure for $_selectedCategory loan is ${_getMaxTenureMonths(_selectedCategory)} months (${_getMaxTenureMonths(_selectedCategory) ~/ 12} yrs)",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── EMI PREVIEW BAR (IF CALCULATED) ──
                      if (_previewEMI != null && _previewEMI! > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: primaryIndigo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryIndigo.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Estimated Monthly EMI:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                NumberFormat.simpleCurrency(
                                        name: 'INR', decimalDigits: 0)
                                    .format(_previewEMI!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: primaryIndigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── 3. INFO NOTE BOX ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2442)
                              : const Color(0xFFF1F3FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: primaryIndigo,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Make sure all details are correct before saving.",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFFC0C7E5)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 4. SAVE LOAN BUTTON ──
                      Builder(
                        builder: (context) {
                          final bool canSave = !_isSaving && _isFormValid;
                          String buttonLabel = "SAVE LOAN";
                          IconData buttonIcon = Icons.save_outlined;

                          if (_isSaving) {
                            buttonLabel = "SAVING...";
                          } else if (_isRateExceeded) {
                            buttonLabel = "INTEREST RATE EXCEEDS 50%";
                            buttonIcon = Icons.block_rounded;
                          } else if (_isTenureExceeded) {
                            buttonLabel = "TENURE EXCEEDED";
                            buttonIcon = Icons.block_rounded;
                          } else if (!_isFormValid) {
                            buttonLabel = "FILL ALL REQUIRED FIELDS";
                            buttonIcon = Icons.lock_outline_rounded;
                          }

                          return SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: !canSave
                                    ? const LinearGradient(
                                        colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFF2A36B1), Color(0xFF3B4CCA)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                boxShadow: !canSave
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF2A36B1).withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: canSave ? _saveLoan : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            buttonIcon,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            buttonLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. BOTTOM FOOTER SECURITY BADGE ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: primaryIndigo,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Your data is safe and secure with ",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSub,
                    ),
                  ),
                  const Text(
                    "PayWise",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryIndigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPER WIDGETS ──

  Widget _buildFieldLabel(String label, Color textDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
    );
  }

  Widget _buildIconBox(Color iconBoxBg, Widget child) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: iconBoxBg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required Color iconBoxBg,
    Widget? icon,
    Widget? customPrefixWidget,
    Widget? suffixIcon,
    required Color inputBg,
    required Color inputBorder,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: inputBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(6.0),
        child: _buildIconBox(iconBoxBg, icon ?? customPrefixWidget!),
      ),
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffixIcon,
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}
