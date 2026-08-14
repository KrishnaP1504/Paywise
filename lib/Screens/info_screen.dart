import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softBg = isDark ? Colors.indigo.withValues(alpha: 0.25) : const Color(0xFFEEF0FD);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Learn & Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 20),
            _SectionHeader('Loan Terminology'),
            _buildGlossaryCard(context, softBg, [
              _GlossaryItem('Principal', Icons.account_balance_wallet,
                'The original amount of money borrowed. Your EMI payments reduce this over time.'),
              _GlossaryItem('EMI', Icons.repeat,
                'Equated Monthly Instalment — the fixed amount you pay each month, containing both principal and interest.'),
              _GlossaryItem('Interest Rate', Icons.percent,
                'The annual cost of borrowing, expressed as a percentage. Split into monthly rate (÷ 12) for EMI calculation.'),
              _GlossaryItem('Tenure', Icons.schedule,
                'The total duration of the loan in months. Longer tenure = lower EMI but more interest paid.'),
              _GlossaryItem('Outstanding Balance', Icons.trending_down,
                'The amount still owed to the lender. Reduces with every EMI payment.'),
              _GlossaryItem('Amortization', Icons.bar_chart,
                'The process of paying off the loan in regular instalments. Early EMIs are mostly interest; later ones are mostly principal.'),
            ]),
            const SizedBox(height: 20),
            _SectionHeader('How EMI is Calculated'),
            _buildFormulaCard(context, softBg),
            const SizedBox(height: 20),
            _SectionHeader('Smart Loan Tips'),
            _buildTipsCard(context, softBg, [
              _Tip(Icons.flash_on,
                'Prepay When You Can',
                'Even a small extra payment each month dramatically reduces total interest paid and cuts loan tenure.'),
              _Tip(Icons.swap_horiz,
                'Check Effective Interest Rates',
                'Always evaluate the effective interest rate, not just the advertised rate, to account for processing fees.'),
              _Tip(Icons.calendar_today,
                'Pay Before the Due Date',
                'Paying a few days early avoids penalties and can save interest on daily-reducing balance loans.'),
              _Tip(Icons.show_chart,
                'Refinance When Rates Drop',
                'If market rates fall by 0.5%+, refinancing your home or car loan can save lakhs over the long term.'),
              _Tip(Icons.savings,
                'Use Bonuses Wisely',
                'A lump-sum payment from your yearly bonus is the single fastest way to reduce outstanding principal.'),
            ]),
            const SizedBox(height: 20),
            _SectionHeader('Simulation Guide'),
            _buildSimGuide(context, softBg),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: const [
          Icon(Icons.school_outlined, color: Colors.white, size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Become a Loan Expert', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Understand every aspect of your loans and make smarter financial decisions.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryCard(BuildContext context, Color softBg, List<_GlossaryItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                ),
                title: Text(item.term, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.definition,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4)),
              ),
              if (!isLast)
                Divider(height: 1, indent: 60, color: Colors.grey.withValues(alpha: 0.15)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormulaCard(BuildContext context, Color softBg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
            ),
            child: const Column(
              children: [
                Text('EMI = P × r × (1+r)ⁿ / ((1+r)ⁿ − 1)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.indigo)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _formulaRow('P', 'Principal loan amount'),
          _formulaRow('r', 'Monthly interest rate (Annual Rate ÷ 12 ÷ 100)'),
          _formulaRow('n', 'Total number of monthly instalments (Tenure)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Example: ₹5,00,000 at 8.5% for 5 years → EMI ≈ ₹10,253/month',
                    style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(String variable, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(variable,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(description, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context, Color softBg, List<_Tip> tips) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tip.icon, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(tip.body, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSimGuide(BuildContext context, Color softBg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guides = [
      const _GuideItem(Icons.add_circle_outline, 'Extra EMI Tab',
          'Use the slider to add an extra amount to your monthly EMI. See how many months and how much interest you save in real time.'),
      const _GuideItem(Icons.savings_outlined, 'Lump Sum Tab',
          'Got a bonus or windfall? Set the amount and the month you\'ll pay it. The simulator recalculates your entire repayment schedule.'),
      const _GuideItem(Icons.swap_horiz, 'Refinancing Tab',
          'Drag the rate slider to see your new EMI and the total interest saved if you switch banks or negotiate a lower rate.'),
    ];

    return Container(
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
        children: guides.asMap().entries.map((e) {
          final guide = e.value;
          final isLast = e.key == guides.length - 1;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(guide.icon, color: Colors.indigo, size: 22),
                ),
                title: Text(guide.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(guide.body,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4)),
              ),
              if (!isLast)
                Divider(height: 1, indent: 60, color: Colors.grey.withValues(alpha: 0.15)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _GlossaryItem {
  final String term;
  final IconData icon;
  final String definition;
  const _GlossaryItem(this.term, this.icon, this.definition);
}

class _Tip {
  final IconData icon;
  final String title;
  final String body;
  const _Tip(this.icon, this.title, this.body);
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String body;
  const _GuideItem(this.icon, this.title, this.body);
}
