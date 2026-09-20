import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/utils/currency_formatter.dart';
import 'package:paywise/theme/glass_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);
  static final NumberFormat _currencyFormat = AppCurrency.formatter;
  String _selectedAnalysisScope = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LoanProvider>(context, listen: false).initLoans();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  String _formatShortAmount(double amount) {
    if (amount >= 10000000) {
      return "₹${(amount / 10000000).toStringAsFixed(2)}Cr";
    } else if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(2)}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}K";
    } else {
      return "₹${amount.toStringAsFixed(0)}";
    }
  }

  bool _isArchivedToHistory(LoanModel loan) {
    if (!loan.isPaidOff) return false;
    if (loan.lastPaymentDate == null) return true;
    return DateTime.now().difference(loan.lastPaymentDate!).inHours >= 24;
  }

  static ({DateTime nextDueDate, int daysLeft, bool isOverdue, int overdueDays}) _getEmiDueInfo(LoanModel loan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

    final clampedDayThisMonth = min(loan.emiDueDate, daysInMonth(now.year, now.month));
    final thisMonthDueDate = DateTime(now.year, now.month, clampedDayThisMonth);

    // Determine whether payment for the current billing cycle was already made
    bool paidForCurrentCycle = false;
    if (loan.lastPaymentDate != null) {
      final last = loan.lastPaymentDate!;
      if (last.year == now.year && last.month == now.month) {
        paidForCurrentCycle = true;
      } else if (last.isAfter(thisMonthDueDate.subtract(const Duration(days: 25)))) {
        paidForCurrentCycle = true;
      }
    }

    DateTime nextDueDate;
    bool isOverdue = false;
    int overdueDays = 0;

    if (paidForCurrentCycle) {
      // Payment already done this cycle -> Next EMI due in following month
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final clampedDayNextMonth = min(loan.emiDueDate, daysInMonth(nextYear, nextMonth));
      nextDueDate = DateTime(nextYear, nextMonth, clampedDayNextMonth);
    } else {
      if (today.isAfter(thisMonthDueDate)) {
        isOverdue = true;
        overdueDays = today.difference(thisMonthDueDate).inDays;
        nextDueDate = thisMonthDueDate;
      } else {
        nextDueDate = thisMonthDueDate;
      }
    }

    final int daysLeft = isOverdue ? -overdueDays : nextDueDate.difference(today).inDays;

    return (
      nextDueDate: nextDueDate,
      daysLeft: daysLeft,
      isOverdue: isOverdue,
      overdueDays: overdueDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = Provider.of<LoanProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
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

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final String displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (user?.email?.split('@').first ?? "User");

    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final softIconBgColor = isDark ? Colors.indigo.withValues(alpha: 0.2) : const Color(0xFFEEF0FD);
    final bool hasCompletedLoans = loanProvider.loans.any((l) => l.isPaidOff);
    final dashboardLoans = loanProvider.loans.where((l) => !_isArchivedToHistory(l)).toList()
      ..sort((a, b) {
        // 1. Always show active loans first, completed loans last
        if (!a.isPaidOff && b.isPaidOff) return -1;
        if (a.isPaidOff && !b.isPaidOff) return 1;

        // 2. For active loans: sort by nearest EMI due date first (overdue / due today / due soon)
        if (!a.isPaidOff && !b.isPaidOff) {
          final dueA = _getEmiDueInfo(a);
          final dueB = _getEmiDueInfo(b);
          if (dueA.daysLeft != dueB.daysLeft) {
            return dueA.daysLeft.compareTo(dueB.daysLeft);
          }
          return b.outstandingBalance.compareTo(a.outstandingBalance);
        }

        // 3. For completed loans: sort by most recently completed
        final dateA = a.lastPaymentDate ?? a.startDate;
        final dateB = b.lastPaymentDate ?? b.startDate;
        return dateB.compareTo(dateA);
      });

    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 10;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
      ),
      body: GlassBackground(
        child: ScrolledNotificationWrapper(
          isScrolledNotifier: _isScrolled,
          child: RefreshIndicator(
          edgeOffset: topPadding + kToolbarHeight,
          onRefresh: () async {
            Provider.of<LoanProvider>(context, listen: false).initLoans();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 170),
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
                decoration: GlassTheme.gradientCardDecoration(
                  context,
                  colors: const [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  radius: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Outstanding",
                                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  currency.format(loanProvider.totalOutstanding),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Monthly Outflow",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        currency.format(loanProvider.monthlyOutflow),
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Active Loans",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    Text(
                                      "${loanProvider.loans.where((l) => !l.isPaidOff).length}",
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
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
                () {
                  final bool isSpecificLoan = _selectedAnalysisScope != 'all' &&
                      loanProvider.loans.any((l) => l.id == _selectedAnalysisScope);

                  final LoanModel? selectedAnalysisLoan = isSpecificLoan
                      ? loanProvider.loans.firstWhere((l) => l.id == _selectedAnalysisScope)
                      : null;

                  final double analysisPrincipal = selectedAnalysisLoan != null
                      ? selectedAnalysisLoan.principalAmount
                      : totalPrincipal;

                  final double analysisInterest = selectedAnalysisLoan != null
                      ? (selectedAnalysisLoan.totalInterest > 0
                          ? selectedAnalysisLoan.totalInterest
                          : max(0.0, selectedAnalysisLoan.totalPayable - selectedAnalysisLoan.principalAmount))
                      : totalInterest;

                  final double analysisTotalCost = analysisPrincipal + analysisInterest;
                  final int analysisPrincipalPct = analysisTotalCost > 0
                      ? ((analysisPrincipal / analysisTotalCost) * 100).round()
                      : 0;
                  final int analysisInterestPct = analysisTotalCost > 0
                      ? ((analysisInterest / analysisTotalCost) * 100).round()
                      : 0;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: GlassTheme.cardDecoration(context, radius: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with Downward Arrow directly beside "Cost of Debt Analysis"
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'Select Loan Analysis',
                              initialValue: isSpecificLoan ? _selectedAnalysisScope : 'all',
                              elevation: 8,
                              offset: const Offset(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                              onSelected: (val) {
                                setState(() => _selectedAnalysisScope = val);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'all',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.pie_chart_outline_rounded, size: 18, color: Colors.indigo),
                                      const SizedBox(width: 10),
                                      Text(
                                        "All Loans (Portfolio)",
                                        style: TextStyle(
                                          fontWeight: !isSpecificLoan ? FontWeight.bold : FontWeight.normal,
                                          color: !isSpecificLoan ? Colors.indigo : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                ...loanProvider.loans.map((l) {
                                  final bool isSelected = isSpecificLoan && _selectedAnalysisScope == l.id;
                                  return PopupMenuItem<String>(
                                    value: l.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          l.isPaidOff
                                              ? Icons.check_circle_outline_rounded
                                              : Icons.account_balance_wallet_outlined,
                                          size: 18,
                                          color: l.isPaidOff ? Colors.green : Colors.indigo,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            l.title.isNotEmpty ? l.title : '${l.category} Loan',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? Colors.indigo : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Cost of Debt Analysis",
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 22,
                                    color: isDark ? Colors.indigo[300] : Colors.indigo,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedAnalysisLoan != null
                                  ? "Showing: ${selectedAnalysisLoan.title}"
                                  : "Overall Portfolio View",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        if (selectedAnalysisLoan != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: GlassTheme.pillDecoration(context, color: Colors.indigo, radius: 10),
                            child: Row(
                              children: [
                                Icon(selectedAnalysisLoan.categoryIcon, size: 15, color: Colors.indigo),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${selectedAnalysisLoan.title} · ${selectedAnalysisLoan.interestRate}% Interest · EMI: ${currency.format(selectedAnalysisLoan.emiAmount)}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.indigo),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedAnalysisScope = 'all'),
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.close_rounded, size: 16, color: Colors.indigo),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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
                                            value: analysisPrincipal > 0 ? analysisPrincipal : 1,
                                            title: '',
                                            radius: 26,
                                          ),
                                          PieChartSectionData(
                                            color: const Color(0xFFFF9100),
                                            value: analysisInterest > 0 ? analysisInterest : 0.001,
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
                                        _formatShortAmount(analysisTotalCost),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        selectedAnalysisLoan != null ? "Loan Cost" : "Total Cost",
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                                    value: "${currency.format(analysisPrincipal)} ($analysisPrincipalPct%)",
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLegendRow(
                                    color: const Color(0xFFFF9100),
                                    label: "Interest",
                                    value: "${currency.format(analysisInterest)} ($analysisInterestPct%)",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }(),
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
                  if (hasCompletedLoans)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/loan_history'),
                      child: const Row(
                        children: [
                          Text("History", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.history_rounded, size: 18, color: Colors.indigo),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              dashboardLoans.isEmpty
                  ? (hasCompletedLoans
                      ? _buildAllDebtFreeState(context)
                      : _buildEmptyState())
                  : Column(
                      children: dashboardLoans.map((loan) {
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  ),
);
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  Widget _buildAllDebtFreeState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: GlassTheme.cardDecoration(context, radius: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 14),
          const Text(
            "You are 100% Debt Free! 🎉",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "All your loans are fully repaid and archived in History.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/loan_history'),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text("View Loan History", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
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

    final IconData categoryIcon = loan.categoryIcon;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: GlassTheme.cardDecoration(context, radius: 20),
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
                  padding: const EdgeInsets.all(10),
                  decoration: GlassTheme.iconBoxDecoration(context, color: Colors.indigo, radius: 12),
                  child: Icon(categoryIcon, color: Colors.indigo, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loan.lenderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(loan.outstandingBalance),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EMI: ${_currencyFormat.format(loan.emiAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: GlassTheme.pillDecoration(
                    context,
                    color: loan.isPaidOff ? const Color(0xFF2E7D32) : Colors.indigo,
                    radius: 8,
                  ),
                  child: Text(
                    loan.isPaidOff ? 'Closed' : 'Active',
                    style: TextStyle(
                      color: loan.isPaidOff
                          ? const Color(0xFF2E7D32)
                          : (isDark ? const Color(0xFF8C9EFF) : const Color(0xFF283593)),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: _buildEmiDueBadge(loan, isDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                  loan.isPaidOff ? const Color(0xFF10B981) : Colors.indigo,
                ),
              ),
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
        decoration: const BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
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
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
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
        } else if (direction == DismissDirection.endToStart) {
          final bool? shouldDelete = await _showDeleteConfirmationDialog(context, loan);
          return shouldDelete == true;
        }
        return false;
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

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, LoanModel loan) {
    return GlassTheme.showGlassDialog<bool>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
        ),
        title: const Text('Delete Loan?'),
        content: Text(
          'Are you sure you want to delete "${loan.title}"?\n\nThis will remove it from your active loans and schedule it for deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmiDueBadge(LoanModel loan, bool isDark) {
    if (loan.isPaidOff || loan.outstandingBalance <= 0) {
      int hoursLeft = 24;
      if (loan.lastPaymentDate != null) {
        hoursLeft = max(1, 24 - DateTime.now().difference(loan.lastPaymentDate!).inHours);
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: GlassTheme.pillDecoration(context, color: const Color(0xFF2E7D32), radius: 8),
        child: Text(
          '🎉 Paid Off · Moves to History in ${hoursLeft}h',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    final dueInfo = _getEmiDueInfo(loan);
    final bool isOverdue = dueInfo.isOverdue;
    final int overdueDays = dueInfo.overdueDays;
    final int daysLeft = max(0, dueInfo.daysLeft);

    String label;
    Color textColor;

    if (isOverdue) {
      label = overdueDays == 1 ? '⚠️ Overdue: 1 Day' : '⚠️ Overdue: $overdueDays Days';
      textColor = const Color(0xFFD32F2F);
    } else if (daysLeft == 0) {
      label = '⚡ EMI Due: Today';
      textColor = const Color(0xFFE65100);
    } else if (daysLeft == 1) {
      label = '🗓️ EMI Due: Tomorrow';
      textColor = const Color(0xFFF57C00);
    } else {
      label = '🗓️ EMI Due: $daysLeft Days';
      textColor = isDark ? const Color(0xFF9FA8DA) : const Color(0xFF303F9F);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: GlassTheme.pillDecoration(context, color: textColor, radius: 8),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _showQuickPayDialog(BuildContext context, LoanModel loan) {
    final double payableNow = min(loan.emiAmount, loan.outstandingBalance);
    final bool isLastPayment = loan.outstandingBalance < loan.emiAmount;
    final amountCtrl = TextEditingController(text: AppCurrency.format(payableNow, showSymbol: false));
    final formKey = GlobalKey<FormState>();
    final currency = AppCurrency.formatter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF0F172A).withValues(alpha: 0.18),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final isKeyboardOpen = media.viewInsets.bottom > 0;
        final navBarHeight = max(
          media.viewPadding.bottom,
          max(media.padding.bottom, media.systemGestureInsets.bottom),
        );
        final safeBottom = isKeyboardOpen
            ? media.viewInsets.bottom + 16.0
            : max(navBarHeight, 48.0) + 20.0;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: GlassTheme.bottomSheetDecoration(ctx, radius: 28),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  // Specular emerald glow orb for glass depth
                  Positioned(
                    top: -30,
                    right: -30,
                    child: IgnorePointer(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF10B981).withValues(alpha: 0.24),
                                    Colors.transparent,
                                  ]
                                : [
                                    const Color(0xFF34D399).withValues(alpha: 0.28),
                                    Colors.transparent,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // VisionOS Specular Bevel Rim Highlight along top curved edge
                  Positioned(
                    top: 0,
                    left: 28,
                    right: 28,
                    height: 1.6,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: isDark ? 0.70 : 0.98),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: safeBottom,
                        left: 20,
                        right: 20,
                        top: 12,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        // Frosted drag handle bar
                        Center(
                          child: Container(
                            width: 44,
                            height: 4.5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white30 : Colors.black26,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Quick Pay — ${loan.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Outstanding: ${currency.format(loan.outstandingBalance)}',
                          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (isLastPayment)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: GlassTheme.pillDecoration(context, color: Colors.green, radius: 8),
                            child: Text(
                              '🎉 Final payment! ${currency.format(loan.outstandingBalance)} remaining.',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            IndianCurrencyInputFormatter(allowDecimals: true),
                          ],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.black.withValues(alpha: 0.03),
                            labelText: isLastPayment ? 'Final Payment Amount' : 'Amount Paid',
                            labelStyle: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                            prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF10B981)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                                width: 1.8,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter amount';
                            final val = AppCurrency.parseClean(v);
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
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final amount = AppCurrency.parseClean(amountCtrl.text) ?? 0.0;
                                Navigator.pop(ctx);
                                try {
                                  await Provider.of<LoanProvider>(context, listen: false)
                                      .recordPayment(loan, amount, DateTime.now());
                                  if (context.mounted) {
                                    UndoToastManager.showSuccessToast(
                                      context: context,
                                      title: "Payment Recorded! 🎉",
                                      subtitle: "${AppCurrency.format(amount)} logged for ${loan.title.isNotEmpty ? loan.title : loan.category}.",
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    final cleanMsg = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '').trim();
                                    UndoToastManager.showErrorToast(
                                      context: context,
                                      title: "Payment Failed",
                                      subtitle: cleanMsg,
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text(
                              'CONFIRM PAYMENT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
},
);
}
}
