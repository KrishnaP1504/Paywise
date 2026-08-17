import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/widgets/undo_toast.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  static final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatShortAmount(double amount) {
    if (amount >= 10000000) {
      return "₹${(amount / 10000000).toStringAsFixed(2)}Cr";
    } else if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(2)}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}k";
    } else {
      return "₹${amount.toStringAsFixed(0)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = Provider.of<LoanProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = _currencyFormat;

    double totalPrincipal = 0;
    double totalInterest = 0;
    for (var loan in loanProvider.loans) {
      if (!loan.isPaidOff) {
        totalPrincipal += loan.principalAmount;
        totalInterest += (loan.totalPayable - loan.principalAmount);
      }
    }
    final double totalCost = totalPrincipal + totalInterest;
    final int principalPct = totalCost > 0 ? ((totalPrincipal / totalCost) * 100).round() : 0;
    final int interestPct = totalCost > 0 ? ((totalInterest / totalCost) * 100).round() : 0;

    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (user?.email?.split('@').first ?? "User");

    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final softIconBgColor = isDark ? Colors.indigo.withValues(alpha: 0.2) : const Color(0xFFEEF0FD);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Provider.of<LoanProvider>(context, listen: false).initLoans();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. USER GREETING HEADER ──
              Text(
                "Welcome back, $displayName 👋",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your financial overview",
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
              ),

              const SizedBox(height: 20),

              // ── 2. HERO TOTAL OUTSTANDING CARD ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3C72).withValues(alpha: 0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Outstanding",
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currency.format(loanProvider.totalOutstanding),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDynamicTrendBadge(loanProvider),
                          ],
                        ),
                        // Wallet Icon Circle
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),

                    // Card Bottom Stats Row
                    Row(
                      children: [
                        // Monthly Outflow
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Monthly Outflow", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text(
                                    currency.format(loanProvider.monthlyOutflow),
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        const SizedBox(width: 16),
                        // Active Loans
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Active Loans", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  Text(
                                    "${loanProvider.loans.where((l) => !l.isPaidOff).length}",
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 3. COST OF DEBT ANALYSIS CARD ──
              if (loanProvider.loans.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Cost of Debt Analysis",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Donut Chart & Legend
                      Row(
                        children: [
                          // Donut Chart with Center Text
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                RepaintBoundary(
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 38,
                                      sections: [
                                        PieChartSectionData(
                                          color: const Color(0xFF2979FF),
                                          value: totalPrincipal > 0 ? totalPrincipal : 1,
                                          title: '',
                                          radius: 26,
                                        ),
                                        PieChartSectionData(
                                          color: const Color(0xFFFF9100),
                                          value: totalInterest,
                                          title: '',
                                          radius: 26,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatShortAmount(totalCost),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Total Cost",
                                      style: TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 20),

                          // Legend Details
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendRow(
                                  color: const Color(0xFF2979FF),
                                  label: "Principal",
                                  value: "${currency.format(totalPrincipal)} ($principalPct%)",
                                ),
                                const SizedBox(height: 16),
                                _buildLegendRow(
                                  color: const Color(0xFFFF9100),
                                  label: "Interest",
                                  value: "${currency.format(totalInterest)} ($interestPct%)",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── 4. YOUR LOANS SECTION ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Loans",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: const [
                        Text("View all", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right, size: 16, color: Colors.indigo),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              loanProvider.loans.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: loanProvider.loans.map((loan) {
                        return _buildLoanCard(
                          context,
                          loan,
                          settings.swipeActionsEnabled,
                          cardBgColor,
                          softIconBgColor,
                          isDark,
                        );
                      }).toList(),
                    ),

              SizedBox(height: 110.0 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 108.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/add_loan'),
          backgroundColor: const Color(0xFF1E3C72),
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.add),
          label: const Text("Add Loan", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDynamicTrendBadge(LoanProvider loanProvider) {
    final double currentTotal = loanProvider.totalOutstanding;
    final double previousTotal = loanProvider.previousMonthOutstanding;

    // Fallback if no history or initial state:
    if (currentTotal <= 0 || previousTotal <= 0) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "0%",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "vs last month",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    final double pctChange = ((currentTotal - previousTotal) / previousTotal) * 100;

    if (pctChange > 0.05) {
      // Positive percentage change -> Total Outstanding INCREASED (Red badge)
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "↑ ${pctChange.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "vs last month",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else if (pctChange < -0.05) {
      // Negative percentage change -> Total Outstanding DECREASED (Green badge)
      final double absPct = pctChange.abs();
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "↓ ${absPct.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "vs last month",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else {
      // Zero change
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "0%",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "vs last month",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.description_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("No loans added yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Home': return Icons.home_rounded;
      case 'Car': return Icons.directions_car_rounded;
      case 'Education': return Icons.school_rounded;
      case 'Business': return Icons.store_rounded;
      case 'Gold': return Icons.monetization_on_rounded;
      default: return Icons.person_rounded;
    }
  }

  Widget _buildLoanCard(
    BuildContext context,
    LoanModel loan,
    bool swipeEnabled,
    Color cardBgColor,
    Color softIconBgColor,
    bool isDark,
  ) {
    double progress = 0;
    if (loan.principalAmount > 0) {
      progress = (loan.principalAmount - loan.outstandingBalance) / loan.principalAmount;
    }
    progress = progress.clamp(0.0, 1.0);

    final IconData categoryIcon = _getCategoryIcon(loan.category);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/loan_details', arguments: loan),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: softIconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(categoryIcon, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loan.lenderName,
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: loan.isPaidOff ? const Color(0xFFE8F5E9) : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              loan.isPaidOff ? 'Closed' : 'Active',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🗓️ EMI Due: 5 Days',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!swipeEnabled || loan.isPaidOff) return card;

    return Dismissible(
      key: ValueKey(loan.id),
      background: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Pay EMI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showQuickPayDialog(context, loan);
          return false;
        } else {
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          UndoToastManager.showUndoDeleteToast(
            context: context,
            loan: loan,
          );
        }
      },
      child: card,
    );
  }

  void _showQuickPayDialog(BuildContext context, LoanModel loan) {
    final double payableNow = min(loan.emiAmount, loan.outstandingBalance);
    final bool isLastPayment = loan.outstandingBalance < loan.emiAmount;
    final amountCtrl = TextEditingController(text: payableNow.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Quick Pay — ${loan.title}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Outstanding: ${currency.format(loan.outstandingBalance)}',
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (isLastPayment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text('🎉 Final payment! ${currency.format(loan.outstandingBalance)} remaining.',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isLastPayment ? 'Final Payment Amount' : 'Amount Paid',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Invalid amount';
                  if (val > loan.outstandingBalance + 10) return 'Max: ${currency.format(loan.outstandingBalance)}';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final amount = double.parse(amountCtrl.text);
                      Navigator.pop(ctx);
                      try {
                        await Provider.of<LoanProvider>(context, listen: false)
                            .recordPayment(loan, amount, DateTime.now());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment recorded!'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('CONFIRM PAYMENT'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
