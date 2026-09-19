import 'package:flutter/material.dart';
import 'package:paywise/theme/glass_theme.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Learn & Info',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        automaticallyImplyLeading: false,
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
      ),
      body: GlassBackground(
        child: ScrolledNotificationWrapper(
          isScrolledNotifier: _isScrolled,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context),
                const SizedBox(height: 24),

                // ── 1. CORE LOAN FOUNDATIONS ──
                const _SectionHeader('Core Loan Foundations'),
                _buildGlossaryCard(context, [
                  const _GlossaryItem(
                    'Principal',
                    Icons.account_balance_wallet_outlined,
                    'The actual amount of money you borrow. It does not include interest or extra fees.',
                  ),
                  const _GlossaryItem(
                    'Interest Rate',
                    Icons.percent_rounded,
                    'The percentage the lender charges you to borrow the principal sum.',
                  ),
                  const _GlossaryItem(
                    'Tenure (Loan Term)',
                    Icons.schedule_rounded,
                    'The total duration of time you are given to repay the debt.',
                  ),
                  const _GlossaryItem(
                    'Equated Monthly Installment (EMI)',
                    Icons.event_repeat_rounded,
                    'The fixed monthly payment you make to clear both your principal and interest over time.',
                  ),
                  const _GlossaryItem(
                    'Amortization',
                    Icons.stacked_line_chart_rounded,
                    'The systematic breakdown schedule showing how each monthly payment is split between reducing your principal and paying interest.',
                  ),
                ]),
                const SizedBox(height: 24),

                // ── 2. INTEREST RATE STRUCTURES & SYSTEMS ──
                const _SectionHeader('Interest Rate Structures & Systems'),
                _buildGlossaryCard(context, [
                  const _GlossaryItem(
                    'Fixed-Rate Loan',
                    Icons.lock_clock_outlined,
                    'A loan where the interest rate stays exactly the same during the entire tenure. Your monthly payments never change, protecting you from market spikes.',
                  ),
                  const _GlossaryItem(
                    'Reducing-Balance Loan',
                    Icons.trending_down_rounded,
                    'An interest calculation method where interest is computed only on your remaining outstanding principal. As you pay down your debt each month, the interest amount decreases, saving you substantial money over time.',
                  ),
                  const _GlossaryItem(
                    'Flat-Rate Loan',
                    Icons.show_chart_rounded,
                    'An interest system where interest is charged on the entire, original principal amount throughout the whole loan life. Even if you have paid off half the loan, you still pay interest on the original 100% value. This makes flat-rate loans much more expensive than reducing-balance loans.',
                  ),
                  const _GlossaryItem(
                    'Floating / Variable-Rate Loan',
                    Icons.tune_rounded,
                    'A loan where the interest rate fluctuates up and down based on broader market indexes.',
                  ),
                ]),
                const SizedBox(height: 20),

                // ── THE FLAT VS. REDUCING TRAP CALLOUT CARD ──
                _buildTrapCalloutCard(context),
                const SizedBox(height: 24),

                // ── 3. SECURITY & ASSET RULES ──
                const _SectionHeader('Security & Asset Rules'),
                _buildGlossaryCard(context, [
                  const _GlossaryItem(
                    'Secured Loan',
                    Icons.home_work_outlined,
                    'A loan that requires you to pledge an asset—like a house or car—as safety for the lender. If you default, the lender can seize the asset.',
                  ),
                  const _GlossaryItem(
                    'Unsecured Loan',
                    Icons.credit_card_outlined,
                    'A loan issued based strictly on your credit profile with no physical asset required as safety. Interest rates are usually higher.',
                  ),
                  const _GlossaryItem(
                    'Collateral',
                    Icons.shield_outlined,
                    'The specific asset (real estate, vehicle, gold) used to back a secured loan.',
                  ),
                  const _GlossaryItem(
                    'Loan-to-Value (LTV) Ratio',
                    Icons.pie_chart_outline_rounded,
                    'The maximum percentage of an asset\'s total value that a lender is willing to finance. For example, an 80% LTV on a 10 Lakh asset means a maximum loan of 8 Lakhs.',
                  ),
                ]),
                const SizedBox(height: 24),

                // ── 4. COSTS, FEES & FINANCIAL HEALTH ──
                const _SectionHeader('Costs, Fees & Financial Health'),
                _buildGlossaryCard(context, [
                  const _GlossaryItem(
                    'Annual Percentage Rate (APR)',
                    Icons.calculate_outlined,
                    'The true yearly cost of your loan. It combines the baseline interest rate plus processing fees, insurance, and other closing costs.',
                  ),
                  const _GlossaryItem(
                    'Processing Fee (Origination Fee)',
                    Icons.receipt_long_outlined,
                    'A one-time, upfront charge levied by lenders to review, prepare, and set up your loan application.',
                  ),
                  const _GlossaryItem(
                    'Prepayment Penalty',
                    Icons.money_off_csred_outlined,
                    'A fee charged if you pay off your loan early, used by banks to recoup lost future interest income.',
                  ),
                  const _GlossaryItem(
                    'Credit Score',
                    Icons.speed_rounded,
                    'A numerical summary (often ranging from 300 to 900) evaluating your credit history. High scores grant you access to cheaper interest rates.',
                  ),
                ]),
                const SizedBox(height: 24),

                // ── 5. HIDDEN COSTS & STRUCTURAL PITFALLS ──
                const _SectionHeader('Hidden Costs & Structural Pitfalls'),
                _buildPitfallsCard(context, [
                  const _PitfallItem(
                    'Loan Sanction vs. Loan Disbursement',
                    Icons.compare_arrows_rounded,
                    'Sanction means the bank has approved your profile and agreed to lend to you in theory. Disbursement is when the actual cash is handed over or wired to your account. Interest only starts accumulating upon disbursement.',
                  ),
                  const _PitfallItem(
                    'Processing Fees & Hidden Admin Charges',
                    Icons.account_balance_outlined,
                    'Lenders often subtract processing fees directly from the loan amount before giving it to you. If you are approved for 5,00,000 with a 2% fee, you will only receive 4,90,000 in your bank account, but you still owe interest on the full 5,00,000.',
                  ),
                  const _PitfallItem(
                    'Forced Bundled Insurance',
                    Icons.health_and_safety_outlined,
                    'Many banks will tell you that you must buy life or credit insurance from them to get the loan approved. In most regions, this is optional. You can shop around for cheaper independent insurance or refuse it if you already have coverage.',
                  ),
                ]),
                const SizedBox(height: 24),

                // ── 6. THE LOAN LEGALITIES ──
                const _SectionHeader('The Loan Legalities'),
                _buildLegalitiesCard(context, [
                  const _LegalityItem(
                    'CBR (Credit Bureau Report)',
                    Icons.fact_check_outlined,
                    'Every time you apply for a loan, a hard inquiry is logged on your credit profile. Applying to five banks at the same time makes you look desperate for cash and drops your credit score.',
                  ),
                  const _LegalityItem(
                    'Default & Co-signer Risk',
                    Icons.group_outlined,
                    'If you co-sign a loan for a friend or family member, you are 100% legally responsible for the debt if they stop paying. It impacts your credit capacity exactly as if it were your own loan.',
                  ),
                ]),
                const SizedBox(height: 24),

                // ── 7. SPECIAL CLAUSES & DISTRESS CONDITIONS ──
                const _SectionHeader('Special Clauses & Distress Conditions'),
                _buildGlossaryCard(context, [
                  const _GlossaryItem(
                    'Moratorium',
                    Icons.pause_circle_outline_rounded,
                    'A temporary, legally approved grace period during which you are allowed to pause making loan repayments. Note: Interest typically continues to accumulate during this pause.',
                  ),
                  const _GlossaryItem(
                    'Default',
                    Icons.gavel_rounded,
                    'Failing to make loan payments according to your contract terms, which severely damages your credit score.',
                  ),
                  const _GlossaryItem(
                    'Refinancing',
                    Icons.published_with_changes_rounded,
                    'Taking out a brand-new loan with better terms or lower interest to completely pay off and replace your existing debt.',
                  ),
                ]),
                const SizedBox(height: 24),

                // ── 8. HOW EMI IS CALCULATED ──
                const _SectionHeader('How EMI is Calculated'),
                _buildFormulaCard(context),
                const SizedBox(height: 24),

                // ── 9. SIMULATION GUIDE ──
                const _SectionHeader('Simulation Guide'),
                _buildSimGuide(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlassTheme.gradientCardDecoration(
        context,
        colors: const [Color(0xFF1E3C72), Color(0xFF2A5298)],
        radius: 22,
      ),
      child: const Row(
        children: [
          Icon(Icons.school_outlined, color: Colors.white, size: 44),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Wisdom & Loan Essentials',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Understand the mechanics of borrowing, avoid predatory flat rates, and take complete control of your financial freedom.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrapCalloutCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.12)
            : const Color(0xFFFEF3C7).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.40)
              : const Color(0xFFF59E0B).withValues(alpha: 0.70),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The Flat vs. Reducing Trap',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Lenders often advertise Flat Rates because the percentage sounds lower (for example, a 6% flat rate sounds better than a 10% reducing rate). However, a 6% flat rate is actually much more expensive because you pay interest on money you have already paid back. Always ask your lender for the reducing rate equivalent before signing.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossaryCard(BuildContext context, List<_GlossaryItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: GlassTheme.cardDecoration(context, radius: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            final isFirst = e.key == 0;
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(22) : Radius.zero,
                      bottom: isLast ? const Radius.circular(22) : Radius.zero,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: GlassTheme.iconBoxDecoration(context, color: Colors.indigo, radius: 12),
                    child: Icon(item.icon, color: Colors.indigo, size: 20),
                  ),
                  title: Text(item.term, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.definition,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPitfallsCard(BuildContext context, List<_PitfallItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: GlassTheme.cardDecoration(context, radius: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            final isFirst = e.key == 0;
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(22) : Radius.zero,
                      bottom: isLast ? const Radius.circular(22) : Radius.zero,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: GlassTheme.iconBoxDecoration(
                      context,
                      color: const Color(0xFFE11D48),
                      radius: 12,
                    ),
                    child: Icon(item.icon, color: const Color(0xFFE11D48), size: 20),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegalitiesCard(BuildContext context, List<_LegalityItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: GlassTheme.cardDecoration(context, radius: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            final isFirst = e.key == 0;
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(22) : Radius.zero,
                      bottom: isLast ? const Radius.circular(22) : Radius.zero,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: GlassTheme.iconBoxDecoration(
                      context,
                      color: const Color(0xFF7C3AED),
                      radius: 12,
                    ),
                    child: Icon(item.icon, color: const Color(0xFF7C3AED), size: 20),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GlassTheme.cardDecoration(context, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: GlassTheme.pillDecoration(context, color: Colors.indigo, radius: 12),
            child: const Column(
              children: [
                Text(
                  'EMI = P × r × (1+r)ⁿ / ((1+r)ⁿ − 1)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _formulaRow('P', 'Principal loan amount'),
          _formulaRow('r', 'Monthly interest rate (Annual Rate ÷ 12 ÷ 100)'),
          _formulaRow('n', 'Total number of monthly installments (Tenure in Months)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: GlassTheme.pillDecoration(context, color: const Color(0xFF2E7D32), radius: 10),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Example: ₹5,00,000 at 8.5% for 5 years yields EMI of approximately ₹10,253 per month',
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
            child: Text(
              variable,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(description, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildSimGuide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guides = [
      const _GuideItem(
        Icons.add_circle_outline,
        'Extra EMI Tab',
        'Use the slider to add an extra amount to your monthly EMI. See how many months and how much interest you save in real time.',
      ),
      const _GuideItem(
        Icons.savings_outlined,
        'Lump Sum Tab',
        'Got a bonus or windfall? Set the amount and the month you will pay it. The simulator recalculates your entire repayment schedule.',
      ),
      const _GuideItem(
        Icons.swap_horiz,
        'Refinancing Tab',
        'Drag the rate slider to see your new EMI and the total interest saved if you switch banks or negotiate a lower rate.',
      ),
    ];

    return Container(
      decoration: GlassTheme.cardDecoration(context, radius: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: guides.asMap().entries.map((e) {
            final guide = e.value;
            final isFirst = e.key == 0;
            final isLast = e.key == guides.length - 1;
            return Column(
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(22) : Radius.zero,
                      bottom: isLast ? const Radius.circular(22) : Radius.zero,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: GlassTheme.iconBoxDecoration(context, color: Colors.indigo, radius: 12),
                    child: Icon(guide.icon, color: Colors.indigo, size: 22),
                  ),
                  title: Text(guide.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    guide.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            );
          }).toList(),
        ),
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
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
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

class _PitfallItem {
  final String title;
  final IconData icon;
  final String description;
  const _PitfallItem(this.title, this.icon, this.description);
}

class _LegalityItem {
  final String title;
  final IconData icon;
  final String description;
  const _LegalityItem(this.title, this.icon, this.description);
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String body;
  const _GuideItem(this.icon, this.title, this.body);
}
