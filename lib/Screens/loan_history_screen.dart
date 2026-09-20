import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/services/pdf_service.dart';
import 'package:paywise/widgets/loan_analysis_sheet.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/utils/currency_formatter.dart';
import 'package:paywise/theme/glass_theme.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key});

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = AppCurrency.formatter;

    final loanProvider = Provider.of<LoanProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final completedLoans = loanProvider.loans.where((l) => l.isPaidOff).toList();

    double totalCleared = 0;
    double totalInterestSaved = 0;
    for (final loan in completedLoans) {
      totalCleared += loan.principalAmount;
      final double actualInterest = max(0.0, loan.totalPaid - loan.principalAmount);
      totalInterestSaved += max(0.0, loan.totalInterest - actualInterest);
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 10;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Loan History",
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
        child: completedLoans.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.indigo.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history_rounded, size: 50, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No Completed Loans Yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Loans paid off in full will appear here.",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          : ScrolledNotificationWrapper(
              isScrolledNotifier: _isScrolled,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 40),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HERO COMPLETED STATS CARD ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: GlassTheme.gradientCardDecoration(
                      context,
                      colors: const [Color(0xFF0F766E), Color(0xFF10B981)],
                      radius: 24,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "DEBT-FREE ARCHIVE",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
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
                                  const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${completedLoans.length} Cleared",
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
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currency.format(totalCleared),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Total Principal Debt Cleared",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (totalInterestSaved > 0) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: GlassTheme.pillDecoration(
                              context,
                              color: Colors.white,
                              radius: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.savings_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Saved ~${currency.format(totalInterestSaved)} in interest",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Fully Repaid Loans",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${completedLoans.length} total",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── LIST OF COMPLETED LOANS ──
                  ...completedLoans.map((loan) {
                    final completedDate = loan.lastPaymentDate ?? DateTime.now();
                    final categoryIcon = loan.categoryIcon;

                    final card = Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: GlassTheme.iconBoxDecoration(context, color: Colors.indigo, radius: 14),
                                  child: Icon(categoryIcon, color: Colors.indigo, size: 24),
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
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currency.format(loan.principalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Cleared ${DateFormat('dd MMM yy').format(completedDate)}",
                                      style: TextStyle(
                                        fontSize: 10,
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
                                    color: const Color(0xFF2E7D32),
                                    radius: 8,
                                  ),
                                  child: const Text(
                                    '✅ Completed · 100% Repaid',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Quick Action Buttons on Completed Card
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => showLoanPeriodAnalysis(context, loan),
                                    icon: const Icon(Icons.insights_rounded, size: 16),
                                    label: const Text("Analysis", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.indigo,
                                      side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final schedule = Provider.of<LoanProvider>(context, listen: false)
                                          .getAmortizationSchedule(loan);
                                      await PdfService.generateAndPrint(loan, schedule);
                                    },
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                    label: const Text("PDF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    if (!settings.swipeActionsEnabled) return card;

                    return Dismissible(
                      key: ValueKey("history_${loan.id}"),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            SizedBox(height: 4),
                            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await GlassTheme.showGlassDialog<bool>(
                          context: context,
                          builder: (ctx) => GlassAlertDialog(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
                            title: const Text('Delete Loan Record?'),
                            content: Text('Are you sure you want to delete "${loan.title}" from history?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        Provider.of<LoanProvider>(context, listen: false).deleteLoan(loan.id);
                        UndoToastManager.showSuccessToast(
                          context: context,
                          title: "Record Deleted",
                          subtitle: "${loan.title} removed from history.",
                        );
                      },
                      child: card,
                    );
                  }),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
