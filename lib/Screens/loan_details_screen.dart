import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/models/transaction_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/pdf_service.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/widgets/loan_analysis_sheet.dart';
import 'package:paywise/utils/currency_formatter.dart';
import 'package:paywise/theme/glass_theme.dart';
import 'package:paywise/Screens/loan_analysis_screen.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  Stream<List<TransactionModel>>? _txnStream;
  final Set<String> _deletedIds = {};
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_txnStream == null) {
      final loan = ModalRoute.of(context)!.settings.arguments as LoanModel;
      _txnStream = Provider.of<LoanProvider>(context, listen: false)
          .getTransactionHistory(loan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLoan = ModalRoute.of(context)!.settings.arguments as LoanModel;
    final currency = AppCurrency.formatter;
    final dateFormat = DateFormat('dd MMM yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softIconBg = isDark ? Colors.indigo.withValues(alpha: 0.25) : const Color(0xFFEEF0FD);

    final loan = context.select<LoanProvider, LoanModel>(
      (provider) => provider.loans.firstWhere(
        (l) => l.id == initialLoan.id,
        orElse: () => initialLoan,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loan.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'Loan Analysis',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoanAnalysisScreen(loan: loan)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () async {
              var schedule = Provider.of<LoanProvider>(context, listen: false).getAmortizationSchedule(loan);
              await PdfService.generateAndPrint(loan, schedule);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Loan',
            onPressed: () => _confirmDelete(context, loan),
          ),
        ],
      ),
      body: GlassBackground(
        child: ScrolledNotificationWrapper(
          isScrolledNotifier: _isScrolled,
          child: SafeArea(
            child: Column(
              children: [
          // 0. CONGRATULATIONS BANNER (When loan is paid off)
          if (loan.isPaidOff)
            Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              padding: const EdgeInsets.all(16),
              decoration: GlassTheme.gradientCardDecoration(
                context,
                colors: const [Color(0xFF0F766E), Color(0xFF10B981)],
                radius: 20,
                shadowColor: const Color(0xFF10B981).withValues(alpha: 0.35),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Congratulations! 🎉",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "You have fully cleared all dues on this loan!",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoanAnalysisScreen(loan: loan)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Analysis",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // 1. SUMMARY CARD (PayWise Indigo Gradient or Emerald Gradient if paid off)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            padding: const EdgeInsets.all(20),
            decoration: GlassTheme.gradientCardDecoration(
              context,
              colors: loan.isPaidOff
                  ? const [Color(0xFF134E4A), Color(0xFF0F766E)]
                  : const [Color(0xFF1E3C72), Color(0xFF2A5298)],
              radius: 20,
              shadowColor: (loan.isPaidOff ? const Color(0xFF10B981) : Colors.indigo)
                  .withValues(alpha: 0.3),
            ),
            child: Column(
              children: [
                Text(
                  loan.isPaidOff ? "Loan Status: Debt Free" : "Outstanding Balance",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  loan.isPaidOff ? currency.format(0) : currency.format(loan.outstandingBalance),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: loan.isPaidOff ? 1.0 : (loan.totalPaid / loan.totalPayable).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(loan.isPaidOff ? const Color(0xFF34D399) : Colors.white),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Paid: ${currency.format(loan.totalPaid)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (loan.isPaidOff)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("100% PAID", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 2. KEY DETAILS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _detailBox("Principal", currency.format(loan.principalAmount), Icons.account_balance, context, softIconBg),
                const SizedBox(width: 10),
                _detailBox("Interest", "${loan.interestRate}%", Icons.percent, context, softIconBg),
                const SizedBox(width: 10),
                _detailBox("Tenure", "${loan.tenureMonths} M", Icons.calendar_today, context, softIconBg),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _detailBox("EMI Date", "Day ${loan.emiDueDate}", Icons.event_repeat, context, softIconBg),
                const SizedBox(width: 10),
                _detailBox("Lender", loan.lenderName, Icons.business, context, softIconBg),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Loan Analysis quick-action card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoanAnalysisScreen(loan: loan)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: GlassTheme.cardDecoration(context, radius: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: GlassTheme.iconBoxDecoration(context, color: Colors.indigo, radius: 10),
                      child: const Icon(Icons.insights_rounded, color: Colors.indigo, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Loan Analysis & Breakdown",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Milestones, interest vs principal & PDF statement",
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(8, 24, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // 3. PAYMENT HISTORY
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _txnStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text("No payments recorded yet", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!
                    .where((t) => !_deletedIds.contains(t.id))
                    .toList();

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('No payments recorded yet', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return _TransactionItemTile(
                      key: ValueKey("tx_${t.id}"),
                      transaction: t,
                      loan: loan,
                      currency: currency,
                      dateFormat: dateFormat,
                      onDeleteConfirm: () async {
                        return await GlassTheme.showGlassDialog<bool>(
                          context: context,
                          builder: (ctx) => GlassAlertDialog(
                            icon: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
                            ),
                            title: const Text('Delete Payment?'),
                            content: Text(
                              'Remove this ${currency.format(t.amount)} payment from ${dateFormat.format(t.date)}?\n\nDeleting this record will reverse the payment, restoring ${currency.format(t.amount)} to your outstanding balance.',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDeleted: () async {
                        setState(() => _deletedIds.add(t.id));
                        await Provider.of<LoanProvider>(context, listen: false)
                            .deleteTransaction(loan.id, t.id);
                        if (context.mounted) {
                          UndoToastManager.showSuccessToast(
                            context: context,
                            title: "Payment Removed",
                            subtitle: "Payment of ${currency.format(t.amount)} was removed.",
                          );
                        }
                      },
                    );
                  },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (loan.isPaidOff
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF6366F1) : const Color(0xFF1E3C72)))
                  .withValues(alpha: isDark ? 0.45 : 0.32),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: loan.isPaidOff
                ? FloatingActionButton.extended(
                    heroTag: 'loan_details_analysis_fab',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoanAnalysisScreen(loan: loan)),
                    ),
                    label: const Text(
                      "VIEW LOAN ANALYSIS",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                    icon: const Icon(Icons.insights_rounded, size: 22),
                    backgroundColor: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
                        .withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    focusElevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: isDark ? 0.40 : 0.60),
                        width: 1.4,
                      ),
                    ),
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  )
                : FloatingActionButton.extended(
                    heroTag: 'loan_details_record_payment_fab',
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showPaymentDialog(context, loan);
                    },
                    label: const Text(
                      "RECORD PAYMENT",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 22),
                    backgroundColor: (isDark ? const Color(0xFF6366F1) : const Color(0xFF1E3C72))
                        .withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    focusElevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: isDark ? 0.40 : 0.60),
                        width: 1.4,
                      ),
                    ),
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _detailBox(String label, String value, IconData icon, BuildContext context, Color softIconBg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: GlassTheme.cardDecoration(context, radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: GlassTheme.iconBoxDecoration(context, color: Colors.indigo, radius: 8),
              child: Icon(icon, size: 16, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LoanModel loan) {
    GlassTheme.showGlassDialog(
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
        title: const Text('Delete Loan'),
        content: Text(
          'Are you sure you want to permanently delete "${loan.title}"?\n\nThis will also erase all payment history and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              UndoToastManager.showUndoDeleteToast(
                context: context,
                loan: loan,
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, LoanModel loan) {
    final double payableNow = min(loan.emiAmount, loan.outstandingBalance);
    final bool isLastPayment = loan.outstandingBalance < loan.emiAmount;
    final amountController = TextEditingController(text: AppCurrency.format(payableNow, showSymbol: false));
    final formKey = GlobalKey<FormState>();
    final currency = AppCurrency.formatter;
    DateTime selectedPaymentDate = DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF0F172A).withValues(alpha: 0.18),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isToday = selectedPaymentDate.year == DateTime.now().year &&
              selectedPaymentDate.month == DateTime.now().month &&
              selectedPaymentDate.day == DateTime.now().day;

          final formattedDateStr = DateFormat('MMM dd, yyyy').format(selectedPaymentDate);

          final media = MediaQuery.of(context);
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
                decoration: GlassTheme.bottomSheetDecoration(context, radius: 28),
                child: Stack(
                  clipBehavior: Clip.antiAlias,
                  children: [
                    // Specular ambient glow orb for glass depth
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
                                      const Color(0xFF6366F1).withValues(alpha: 0.25),
                                      Colors.transparent,
                                    ]
                                  : [
                                      const Color(0xFF818CF8).withValues(alpha: 0.28),
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
                                const Text("Record Payment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            Text(
                              "Outstanding: ${currency.format(loan.outstandingBalance)}", 
                              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 12),

                            if (isLastPayment)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: GlassTheme.pillDecoration(context, color: const Color(0xFF2E7D32), radius: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.celebration, color: Color(0xFF2E7D32), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '🎉 Final payment! Only ${currency.format(loan.outstandingBalance)} remaining.',
                                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            TextFormField(
                              controller: amountController,
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
                                prefixIcon: const Icon(Icons.currency_rupee, color: Colors.indigo),
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
                                    color: Colors.indigo,
                                    width: 1.8,
                                  ),
                                ),
                                helperText: isLastPayment
                                    ? 'This is less than your EMI — it clears the loan fully'
                                    : null,
                                helperStyle: const TextStyle(color: Color(0xFF2E7D32)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter amount';
                                double? val = AppCurrency.parseClean(value);
                                if (val == null || val <= 0) return 'Invalid amount';
                                if (val > loan.outstandingBalance + 10) {
                                  return 'Max payment is ${currency.format(loan.outstandingBalance)}';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                  // ── PAYMENT DATE DISPLAY CARD ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.indigo.withValues(alpha: 0.06)
                          : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? Colors.indigo.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isToday ? Icons.event_available_rounded : Icons.history_rounded,
                          color: isToday ? Colors.indigo : Colors.amber[900],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isToday
                                ? "Payment Date: Today ($formattedDateStr)"
                                : "Payment Date: $formattedDateStr (Custom Date)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isToday ? Colors.indigo[900] : Colors.amber[900],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedPaymentDate.isAfter(DateTime.now())
                                  ? DateTime.now()
                                  : selectedPaymentDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedPaymentDate = picked;
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Change Date",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text('• Extra amount automatically reduces principal.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 18),
                  
                  // ── CONFIRM PAYMENT BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          double amount = AppCurrency.parseClean(amountController.text) ?? 0.0;
                          Navigator.pop(context);
                          
                          try {
                            var result = await Provider.of<LoanProvider>(context, listen: false)
                                .recordPayment(loan, amount, selectedPaymentDate);
                            
                            if (context.mounted) {
                              if (result['isPaidOff'] == true) {
                                _showCelebrationDialog(context, result, currency);
                              } else {
                                UndoToastManager.showSuccessToast(
                                  context: context,
                                  title: "Payment Recorded! 🎉",
                                  subtitle: "Payment recorded for ${DateFormat('MMM dd, yyyy').format(selectedPaymentDate)}.",
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              final cleanMsg = e
                                  .toString()
                                  .replaceAll('Exception: ', '')
                                  .replaceAll('Error: ', '')
                                  .trim();
                              UndoToastManager.showErrorToast(
                                context: context,
                                title: "Payment Error",
                                subtitle: cleanMsg,
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: const Text("CONFIRM PAYMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── FORGOTTEN / CUSTOM DATE PAYMENT BUTTON UNDER CONFIRM PAYMENT ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedPaymentDate.isAfter(now) ? now : selectedPaymentDate,
                          firstDate: DateTime(2000),
                          lastDate: now,
                          helpText: "SELECT FORGOTTEN PAYMENT DATE",
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedPaymentDate = picked;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber[900],
                        side: BorderSide(color: Colors.amber[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      label: Text(
                        isToday
                            ? "Forgot to record? Choose Payment Date"
                            : "Selected: $formattedDateStr (Tap to Change)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context, Map<String, dynamic> result, NumberFormat currency) {
    GlassTheme.showGlassDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GlassAlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 54),
          ),
          title: const Text("🎉 Congratulations! 🎉"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("You have fully paid off this loan!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              if (result['amountSaved'] > 0) ...[
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: GlassTheme.pillDecoration(context, color: const Color(0xFF2E7D32), radius: 12),
                   child: Column(
                     children: [
                       const Text("TOTAL SAVINGS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                       Text(currency.format(result['amountSaved']), style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 28, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),
                 const SizedBox(height: 10),
              ],
              if (result['monthsSaved'] > 0) ...[
                Text("⏱️ You finished ${result['monthsSaved']} months early!", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("AWESOME!"),
              ),
            )
          ],
        );
      },
    );
  }
}

class _TransactionItemTile extends StatefulWidget {
  final TransactionModel transaction;
  final LoanModel loan;
  final NumberFormat currency;
  final DateFormat dateFormat;
  final Future<bool?> Function() onDeleteConfirm;
  final void Function() onDeleted;

  const _TransactionItemTile({
    super.key,
    required this.transaction,
    required this.loan,
    required this.currency,
    required this.dateFormat,
    required this.onDeleteConfirm,
    required this.onDeleted,
  });

  @override
  State<_TransactionItemTile> createState() => _TransactionItemTileState();
}

class _TransactionItemTileState extends State<_TransactionItemTile> {
  bool _isSwiping = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final loan = widget.loan;
    final currency = widget.currency;
    final dateFormat = widget.dateFormat;
    final bool isExtra = t.amount > loan.emiAmount + 100;

    final BorderRadius cardRadius = _isSwiping
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            topRight: Radius.zero,
            bottomRight: Radius.zero,
          )
        : BorderRadius.circular(16);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: GlassTheme.cardDecoration(
        context,
        radius: 16,
        customBorderRadius: cardRadius,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: GlassTheme.iconBoxDecoration(
              context,
              color: isExtra ? const Color(0xFF2E7D32) : Colors.indigo,
              radius: 18,
            ),
            child: Icon(
              isExtra ? Icons.star_rounded : Icons.check_circle_rounded,
              color: isExtra ? const Color(0xFF2E7D32) : Colors.indigo,
              size: 18,
            ),
          ),
          title: Text(
            currency.format(t.amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(dateFormat.format(t.date)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isExtra)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: GlassTheme.pillDecoration(
                    context,
                    color: const Color(0xFF2E7D32),
                    radius: 6,
                  ),
                  child: const Text(
                    'Extra Payment',
                    style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.swipe_left_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey("tx_${t.id}"),
      direction: DismissDirection.endToStart,
      onUpdate: (details) {
        final bool swiping = details.progress > 0.002;
        if (swiping != _isSwiping) {
          setState(() => _isSwiping = swiping);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final bool? confirmed = await widget.onDeleteConfirm();
        if (confirmed != true) {
          if (mounted) setState(() => _isSwiping = false);
          return false;
        }
        return true;
      },
      onDismissed: (_) {
        widget.onDeleted();
      },
      child: card,
    );
  }
}
