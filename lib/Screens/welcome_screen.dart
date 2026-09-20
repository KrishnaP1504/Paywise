import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywise/theme/glass_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.88, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
    if (mounted) {
      Navigator.pushNamed(context, '/register');
    }
  }

  Future<void> _onSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
    if (mounted) {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const primaryNavy = Color(0xFF1E3C72);
    const accentIndigo = Color(0xFF3B4CCA);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // ── 1. LOGO WITH GLOWING RING ──
                          ScaleTransition(
                            scale: _glowAnimation,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentIndigo.withValues(alpha: isDark ? 0.45 : 0.28),
                                    blurRadius: 26,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF101322) : Colors.white,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/images/paywise_logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 38,
                                    color: Color(0xFF1E3C72),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── 2. APP TITLE & BRANDING ──
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: isDark
                                  ? [Colors.white, const Color(0xFF90B3E8)]
                                  : [const Color(0xFF1E3C72), const Color(0xFF3B4CCA)],
                            ).createShader(bounds),
                            child: const Text(
                              "PayWise",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Master Your Loans. Beat the Interest.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Your complete loan & EMI intelligence cockpit. Track payoffs, simulate prepayments, and eliminate debt faster.",
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          const Spacer(flex: 1),

                          // ── 3. TWO FROSTED GLASS FEATURE CARDS (Privacy card removed) ──
                          _buildFeatureCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.speed_rounded,
                            iconColor: const Color(0xFF3B4CCA),
                            title: "Smart EMI & Debt Tracking",
                            description:
                                "Consolidate personal, home, and vehicle loans with automated due dates, schedules, and interest curves.",
                          ),

                          const SizedBox(height: 10),

                          _buildFeatureCard(
                            context: context,
                            isDark: isDark,
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: "Prepayment Simulator",
                            description:
                                "Simulate lump-sum prepayments and monthly top-ups. Instantly see how much interest and tenure you save.",
                          ),

                          const Spacer(flex: 2),

                          // ── 4. PRIMARY CTA: GET STARTED ──
                          GlassButton(
                            width: double.infinity,
                            height: 50,
                            radius: 16,
                            onPressed: _onGetStarted,
                            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── 5. SECONDARY CTA: SIGN IN ──
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  width: 1.1,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.white.withValues(alpha: 0.60),
                              ),
                              onPressed: _onSignIn,
                              child: Text(
                                "Already have an account? Sign In",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : primaryNavy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: GlassTheme.cardDecoration(context, radius: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
