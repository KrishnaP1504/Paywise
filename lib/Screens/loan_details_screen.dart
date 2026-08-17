import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/models/transaction_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/pdf_service.dart';
import 'package:paywise/widgets/undo_toast.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  Stream<List<TransactionModel>>? _txnStream;
  final Set<String> _deletedIds = {};

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
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softIconBg = isDark ? Colors.indigo.withValues(alpha: 0.25) : const Color(0xFFEEF0FD);

    final loanProvider = context.watch<LoanProvider>();
    final loan = loanProvider.loans.firstWhere(
      (l) => l.id == initialLoan.id,
      orElse: () => initialLoan,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () async {
              var schedule = Provider.of<LoanProvider>(context, listen: false).getAmortizationSchedule(loan);
              await PdfService().generateAndPrint(loan, schedule);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Loan',
            onPressed: () => _confirmDelete(context, loan),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          // 1. SUMMARY CARD (PayWise Indigo Gradient)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                const Text("Outstanding Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 5),
                Text(
                  currency.format(loan.outstandingBalance),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (loan.totalPaid / loan.totalPayable).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text("Paid: ${currency.format(loan.totalPaid)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // 2. KEY DETAILS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _detailBox("EMI Date", "Day ${loan.emiDueDate}", Icons.event_repeat, context, softIconBg),
                const SizedBox(width: 10),
                _detailBox("Lender", loan.lenderName, Icons.business, context, softIconBg),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final bool isExtra = t.amount > loan.emiAmount + 100;

                    return Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
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
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete Payment?'),
                            content: Text(
                              'Remove this ${currency.format(t.amount)} payment from ${dateFormat.format(t.date)}?\n\nNote: This only removes the record — the loan balance is managed by Firestore.'),
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
                      onDismissed: (_) async {
                        setState(() => _deletedIds.add(t.id));
                        await Provider.of<LoanProvider>(context, listen: false)
                            .deleteTransaction(loan.id, t.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment of ${currency.format(t.amount)} removed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isExtra ? const Color(0xFFE8F5E9) : softIconBg,
                            child: Icon(
                              isExtra ? Icons.star_rounded : Icons.check_circle_rounded,
                              color: isExtra ? const Color(0xFF2E7D32) : Colors.indigo,
                              size: 18,
                            ),
                          ),
                          title: Text(currency.format(t.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text(dateFormat.format(t.date)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isExtra)
                                const Text('Extra Payment',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.swipe_left_rounded, size: 14, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton.extended(
          onPressed: loan.isPaidOff 
              ? null 
              : () {
                  HapticFeedback.mediumImpact();
                  _showPaymentDialog(context, loan);
                },
          label: const Text("RECORD PAYMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          icon: const Icon(Icons.payment_rounded, size: 22),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 6,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _detailBox(String label, String value, IconData icon, BuildContext context, Color softIconBg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.indigo),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LoanModel loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Loan', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${loan.title}"?\n\nThis will also erase all payment history and cannot be undone.',
          style: const TextStyle(height: 1.5),
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
    final amountController = TextEditingController(text: payableNow.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();
    final currency = NumberFormat.simpleCurrency(name: 'INR', decimalDigits: 0);
    DateTime selectedPaymentDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isToday = selectedPaymentDate.year == DateTime.now().year &&
              selectedPaymentDate.month == DateTime.now().month &&
              selectedPaymentDate.day == DateTime.now().day;

          final formattedDateStr = DateFormat('MMM dd, yyyy').format(selectedPaymentDate);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2E7D32)),
                      ),
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
                    decoration: InputDecoration(
                      labelText: isLastPayment ? 'Final Payment Amount' : 'Amount Paid',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      helperText: isLastPayment
                          ? 'This is less than your EMI — it clears the loan fully'
                          : null,
                      helperStyle: const TextStyle(color: Color(0xFF2E7D32)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter amount';
                      double? val = double.tryParse(value);
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
                          double amount = double.parse(amountController.text);
                          Navigator.pop(context);
                          
                          try {
                            var result = await Provider.of<LoanProvider>(context, listen: false)
                                .recordPayment(loan, amount, selectedPaymentDate);
                            
                            if (context.mounted) {
                              if (result['isPaidOff'] == true) {
                                _showCelebrationDialog(context, result, currency);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Payment Recorded for ${DateFormat('MMM dd, yyyy').format(selectedPaymentDate)}!",
                                    ),
                                  ),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          cleanMsg,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFFD97706),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("CONFIRM PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── FORGOTTEN / CUSTOM DATE PAYMENT BUTTON UNDER CONFIRM PAYMENT ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedPaymentDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
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
          );
        },
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context, Map<String, dynamic> result, NumberFormat currency) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("🎉 Congratulations! 🎉", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 80),
              const SizedBox(height: 16),
              const Text("You have fully paid off this loan!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              if (result['amountSaved'] > 0) ...[
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
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
