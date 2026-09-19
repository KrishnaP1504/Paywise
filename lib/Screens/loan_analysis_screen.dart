import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/models/transaction_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/pdf_service.dart';
import 'package:paywise/utils/currency_formatter.dart';
import 'package:paywise/theme/glass_theme.dart';

class LoanAnalysisScreen extends StatefulWidget {
  final LoanModel loan;
  const LoanAnalysisScreen({super.key, required this.loan});

  @override
  State<LoanAnalysisScreen> createState() => _LoanAnalysisScreenState();
}

class _LoanAnalysisScreenState extends State<LoanAnalysisScreen> {
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);
  bool _showFullProjection = false;

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  String _formatShortAmount(double amount) {
    if (amount >= 10000000) {
      return "₹${(amount / 10000000).toStringAsFixed(1)}Cr";
    } else if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(1)}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}K";
    } else {
      return "₹${amount.toStringAsFixed(0)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = AppCurrency.formatter;

    // Retrieve live loan from provider if available
    final loanProvider = Provider.of<LoanProvider>(context);
    final loan = loanProvider.loans.firstWhere(
      (l) => l.id == widget.loan.id,
      orElse: () => widget.loan,
    );

    final DateTime completionDate = loan.lastPaymentDate ?? DateTime.now();
    final int daysTaken = max(1, completionDate.difference(loan.startDate).inDays);
    final int monthsTaken = max(1, (daysTaken / 30).ceil());
    final int monthsSaved = max(0, loan.tenureMonths - monthsTaken);

    final double actualInterest = max(0.0, loan.totalPaid - loan.principalAmount);
    final double interestSaved = max(0.0, loan.totalInterest - actualInterest);

    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 10;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final schedule = loanProvider.getAmortizationSchedule(loan);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${loan.title} Analysis",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "Download PDF Statement",
            onPressed: () async {
              await PdfService.generateAndPrint(loan, schedule);
            },
          ),
        ],
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
      ),
      body: GlassBackground(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels > 10 && !_isScrolled.value) {
              _isScrolled.value = true;
            } else if (notification.metrics.pixels <= 10 && _isScrolled.value) {
              _isScrolled.value = false;
            }
            return false;
          },
          child: StreamBuilder<List<TransactionModel>>(
            stream: loanProvider.getTransactionHistory(loan.id),
            builder: (context, snapshot) {
              final txns = snapshot.data ?? [];
              final int paymentCount = txns.length;
              final double avgPayment =
                  paymentCount > 0 ? (loan.totalPaid / paymentCount) : loan.emiAmount;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, bottomPadding + 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. HERO MILESTONE CARD ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: GlassTheme.gradientCardDecoration(
                        context,
                        colors: loan.isPaidOff
                            ? const [Color(0xFF0F766E), Color(0xFF10B981)]
                            : const [Color(0xFF1E3C72), Color(0xFF2A5298)],
                        radius: 24,
                        shadowColor: (loan.isPaidOff
                                ? const Color(0xFF10B981)
                                : Colors.indigo)
                            .withValues(alpha: 0.35),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loan.isPaidOff ? "STATUS: DEBT FREE" : "STATUS: ACTIVE LOAN",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: GlassTheme.pillDecoration(
                                  context,
                                  color: Colors.white,
                                  radius: 20,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      loan.isPaidOff
                                          ? Icons.verified_rounded
                                          : Icons.timelapse_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      loan.isPaidOff
                                          ? "100% Repaid"
                                          : "${loan.totalPayable > 0 ? ((loan.totalPaid / loan.totalPayable) * 100).round() : 0}% Repaid",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currency.format(loan.totalPaid),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total Amount Cleared",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (interestSaved > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: GlassTheme.pillDecoration(
                                context,
                                color: Colors.white,
                                radius: 14,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Saved ~${currency.format(interestSaved)} on interest!",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 2. DYNAMIC AMORTIZATION TRAJECTORY CHART (Moves with each Payment) ──
                    _buildTrajectoryChartCard(context, loan, schedule, txns),
                    const SizedBox(height: 18),

                    // ── 3. LIFECYCLE TIMELINE CARD ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Loan Timeline & Duration",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: GlassTheme.cardDecoration(context, radius: 20),
                      child: Column(
                        children: [
                          _buildTimelineRow(
                            context: context,
                            icon: Icons.calendar_today_rounded,
                            color: Colors.blue,
                            label: "Start Date",
                            value: DateFormat('MMM dd, yyyy').format(loan.startDate),
                          ),
                          const Divider(height: 20),
                          _buildTimelineRow(
                            context: context,
                            icon: loan.isPaidOff
                                ? Icons.check_circle_rounded
                                : Icons.pending_actions_rounded,
                            color: loan.isPaidOff ? const Color(0xFF10B981) : Colors.orange,
                            label: loan.isPaidOff ? "Completion Date" : "Last Recorded Payment",
                            value: DateFormat('MMM dd, yyyy').format(completionDate),
                          ),
                          const Divider(height: 20),
                          _buildTimelineRow(
                            context: context,
                            icon: Icons.timer_outlined,
                            color: Colors.purple,
                            label: "Repayment Speed",
                            value: loan.isPaidOff
                                ? (monthsSaved > 0
                                    ? "$monthsTaken mo ($monthsSaved mo ahead of plan! 🚀)"
                                    : "$monthsTaken months (On schedule)")
                                : "$monthsTaken months elapsed of ${loan.tenureMonths} mo",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 4. FINANCIAL BREAKDOWN CARD ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Financial Breakdown",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: GlassTheme.cardDecoration(context, radius: 20),
                      child: Column(
                        children: [
                          _buildStatRow(
                            label: "Original Principal",
                            value: currency.format(loan.principalAmount),
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            label: "Annual Interest Rate",
                            value: "${loan.interestRate}%",
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            label: "Actual Interest Paid",
                            value: currency.format(actualInterest),
                            color: const Color(0xFFF59E0B),
                          ),
                          if (interestSaved > 0) ...[
                            const SizedBox(height: 12),
                            _buildStatRow(
                              label: "Interest Saved by Prepayments",
                              value: currency.format(interestSaved),
                              color: const Color(0xFF10B981),
                              isBold: true,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildStatRow(
                            label: "Total Payments Recorded",
                            value: "$paymentCount payments",
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            label: "Average Payment Amount",
                            value: currency.format(avgPayment),
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 5. STATEMENT PDF BUTTON ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await PdfService.generateAndPrint(loan, schedule);
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                        label: const Text(
                          "Download Full Loan Statement (PDF)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3C72),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrajectoryChartCard(
    BuildContext context,
    LoanModel loan,
    List<AmortizationRow> schedule,
    List<TransactionModel> txns,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = AppCurrency.formatter;

    // Sort user payments chronologically
    final sortedTxns = List<TransactionModel>.from(txns)
      ..sort((a, b) => a.date.compareTo(b.date));

    final int livePaymentsCount = sortedTxns.length;

    // ── Build Live Trajectory Spots (from user's actual recorded payments) ──
    final List<FlSpot> liveRemainingSpots = [];
    final List<FlSpot> livePrincipalSpots = [];
    final List<FlSpot> liveInterestSpots = [];

    // Point 0 (Start Date / Loan Origination)
    liveRemainingSpots.add(FlSpot(0, loan.principalAmount));
    livePrincipalSpots.add(const FlSpot(0, 0));
    liveInterestSpots.add(const FlSpot(0, 0));

    double runningBalance = loan.principalAmount;
    double runningPrincipalPaid = 0.0;
    double runningInterestPaid = 0.0;
    final double monthlyRate = (loan.interestRate / 12) / 100;

    for (int i = 0; i < sortedTxns.length; i++) {
      final txn = sortedTxns[i];
      final double xVal = (i + 1).toDouble();

      double periodInterest = runningBalance * monthlyRate;
      double principalPart = txn.amount - periodInterest;

      if (principalPart < 0) {
        principalPart = 0;
        periodInterest = txn.amount;
      }
      if (principalPart > runningBalance) {
        principalPart = runningBalance;
      }

      runningBalance = max(0.0, runningBalance - principalPart);
      runningPrincipalPaid += principalPart;
      runningInterestPaid += periodInterest;

      // If this is the latest transaction and loan has specific live totals, calibrate
      if (i == sortedTxns.length - 1 && loan.isPaidOff) {
        runningBalance = 0.0;
        runningPrincipalPaid = loan.principalAmount;
        runningInterestPaid = max(0.0, loan.totalPaid - loan.principalAmount);
      }

      liveRemainingSpots.add(FlSpot(xVal, runningBalance));
      livePrincipalSpots.add(FlSpot(xVal, runningPrincipalPaid));
      liveInterestSpots.add(FlSpot(xVal, runningInterestPaid));
    }

    // ── Build Full Plan Theoretical Spots (for Projection mode) ──
    final bool isTenureShort = loan.tenureMonths <= 12;
    final double fullTotalX = isTenureShort ? loan.tenureMonths.toDouble() : (loan.tenureMonths / 12.0);
    final int fullMaxSteps = isTenureShort ? loan.tenureMonths : fullTotalX.ceil();
    final int fullStepInterval = isTenureShort
        ? (loan.tenureMonths <= 6 ? 1 : 2)
        : (fullTotalX <= 5 ? 1 : (fullTotalX <= 10 ? 2 : 5));

    final List<FlSpot> planRemainingSpots = [];
    final List<FlSpot> planPrincipalSpots = [];
    final List<FlSpot> planInterestSpots = [];

    final List<double> cumPlanPrincipal = [];
    final List<double> cumPlanInterest = [];
    double pAcc = 0.0;
    double iAcc = 0.0;
    for (var row in schedule) {
      pAcc += row.principalComponent;
      iAcc += row.interestComponent;
      cumPlanPrincipal.add(pAcc);
      cumPlanInterest.add(iAcc);
    }

    planRemainingSpots.add(FlSpot(0, loan.principalAmount));
    planPrincipalSpots.add(const FlSpot(0, 0));
    planInterestSpots.add(const FlSpot(0, 0));

    for (int step = 1; step <= fullMaxSteps; step++) {
      final int monthIdx = isTenureShort ? step : min(step * 12, loan.tenureMonths);
      if (monthIdx > 0 && monthIdx <= schedule.length) {
        final double rem = schedule[monthIdx - 1].closingBalance;
        final double pPaid = cumPlanPrincipal[monthIdx - 1];
        final double iPaid = cumPlanInterest[monthIdx - 1];
        final double xVal = step.toDouble();

        planRemainingSpots.add(FlSpot(xVal, rem));
        planPrincipalSpots.add(FlSpot(xVal, pPaid));
        planInterestSpots.add(FlSpot(xVal, iPaid));
      }
    }

    // Determine active chart configuration
    final bool useLiveMode = !_showFullProjection;
    final List<FlSpot> activeRemainingSpots = useLiveMode ? liveRemainingSpots : planRemainingSpots;
    final List<FlSpot> activePrincipalSpots = useLiveMode ? livePrincipalSpots : planPrincipalSpots;
    final List<FlSpot> activeInterestSpots = useLiveMode ? liveInterestSpots : planInterestSpots;

    final double activeMaxX = useLiveMode
        ? max(1.0, livePaymentsCount.toDouble())
        : fullMaxSteps.toDouble();

    final double maxPrincipal = max(1.0, loan.principalAmount);
    final double maxY = maxPrincipal * 1.08;

    int liveInterval = 1;
    if (livePaymentsCount > 18) {
      liveInterval = 5;
    } else if (livePaymentsCount > 8) {
      liveInterval = 2;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlassTheme.cardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row with Toggle Switch ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Amortization Trajectory",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    useLiveMode
                        ? (livePaymentsCount == 0
                            ? "Awaiting first recorded payment"
                            : "Live trajectory ($livePaymentsCount payments recorded)")
                        : "Full plan projection (${loan.tenureMonths} months)",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Segmented Toggle between Live Payments and Full Plan
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_showFullProjection) {
                          setState(() => _showFullProjection = false);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: !_showFullProjection ? Colors.indigo : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Live ($livePaymentsCount)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: !_showFullProjection
                                ? Colors.white
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!_showFullProjection) {
                          setState(() => _showFullProjection = true);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _showFullProjection ? Colors.indigo : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Full Plan",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _showFullProjection
                                ? Colors.white
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Legend Row (Matching User Image: Blue/Purple, Green, Orange) ──
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                color: const Color(0xFF6366F1),
                label: "Remaining Balance",
                isDark: isDark,
              ),
              _buildLegendItem(
                color: const Color(0xFF10B981),
                label: "Principal Paid",
                isDark: isDark,
              ),
              _buildLegendItem(
                color: const Color(0xFFF59E0B),
                label: "Interest Paid",
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Empty State if in Live Mode and 0 Payments Recorded ──
          if (useLiveMode && livePaymentsCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timeline_rounded, color: Colors.indigo, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No Payments Recorded Yet",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "As you log EMI payments, your live trajectory will advance here.\nTap 'Full Plan' above to preview the full tenure projection.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _showFullProjection = true);
                    },
                    icon: const Icon(Icons.insights_rounded, size: 16),
                    label: const Text("View Full Plan Projection", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          else
            // ── Multi-Line Chart (Dynamic & Interactive) ──
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxPrincipal > 0 ? (maxPrincipal / 2) : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: maxPrincipal > 0 ? (maxPrincipal / 2) : 1,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > maxPrincipal * 1.02) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              _formatShortAmount(value),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: useLiveMode
                            ? liveInterval.toDouble()
                            : fullStepInterval.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final int stepInt = value.toInt();
                          if (value != stepInt.toDouble()) return const SizedBox.shrink();
                          if (stepInt < 0 || stepInt > activeMaxX.toInt()) {
                            return const SizedBox.shrink();
                          }

                          String label;
                          if (useLiveMode) {
                            label = stepInt == 0 ? "Start" : "P$stepInt";
                          } else {
                            label = isTenureShort ? "Mo $stepInt" : "Year $stepInt";
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: activeMaxX,
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // 1. Remaining Balance (Indigo/Purple)
                    LineChartBarData(
                      spots: activeRemainingSpots,
                      isCurved: true,
                      curveSmoothness: 0.12,
                      color: const Color(0xFF6366F1),
                      barWidth: 3.2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: useLiveMode && livePaymentsCount <= 12,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: const Color(0xFF6366F1),
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                    // 2. Principal Paid (Emerald Green)
                    LineChartBarData(
                      spots: activePrincipalSpots,
                      isCurved: true,
                      curveSmoothness: 0.12,
                      color: const Color(0xFF10B981),
                      barWidth: 3.2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: useLiveMode && livePaymentsCount <= 12,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: const Color(0xFF10B981),
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                    // 3. Interest Paid (Amber Orange)
                    LineChartBarData(
                      spots: activeInterestSpots,
                      isCurved: true,
                      curveSmoothness: 0.12,
                      color: const Color(0xFFF59E0B),
                      barWidth: 3.2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: useLiveMode && livePaymentsCount <= 12,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: const Color(0xFFF59E0B),
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.96),
                      tooltipBorder: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      tooltipRoundedRadius: 12,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((barSpot) {
                          String name = "Value";
                          Color textColor = Colors.white;
                          if (barSpot.barIndex == 0) {
                            name = "Remaining";
                            textColor = const Color(0xFF818CF8);
                          } else if (barSpot.barIndex == 1) {
                            name = "Principal Paid";
                            textColor = const Color(0xFF34D399);
                          } else if (barSpot.barIndex == 2) {
                            name = "Interest Paid";
                            textColor = const Color(0xFFFBBF24);
                          }

                          return LineTooltipItem(
                            "$name: ${currency.format(barSpot.y)}",
                            TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
