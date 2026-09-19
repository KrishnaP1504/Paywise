import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:paywise/Screens/dashboard_screen.dart';
import 'package:paywise/Screens/simulation_screen.dart';
import 'package:paywise/Screens/info_screen.dart';
import 'package:paywise/Screens/profile_screen.dart';
import 'package:paywise/theme/glass_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isAppBlurred = false;

  final List<Widget> _pages = const [
    DashboardScreen(key: ValueKey('home')),
    SimulationScreen(key: ValueKey('simulate')),
    InfoScreen(key: ValueKey('info')),
    ProfileScreen(key: ValueKey('settings')),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      setState(() => _isAppBlurred = true);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isAppBlurred = false);
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePillBg = isDark
        ? const Color(0xFF6366F1).withValues(alpha: 0.24)
        : const Color(0xFF4F46E5).withValues(alpha: 0.12);
    final activeBorderColor = isDark
        ? const Color(0xFF818CF8).withValues(alpha: 0.40)
        : const Color(0xFF6366F1).withValues(alpha: 0.28);
    final activeColor = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF3730A3);
    final inactiveColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: SafeArea(
            top: false,
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          floatingActionButton: AnimatedScale(
            scale: _currentIndex == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _currentIndex == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring: _currentIndex != 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF1E3C72))
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
                      child: FloatingActionButton.extended(
                        heroTag: 'dashboard_add_loan_fab',
                        onPressed: () => Navigator.pushNamed(context, '/add_loan'),
                        backgroundColor: isDark
                            ? const Color(0xFF6366F1).withValues(alpha: 0.82)
                            : const Color(0xFF1E3C72).withValues(alpha: 0.85),
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
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          "Add Loan",
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
        child: GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          borderRadius: 36,
          blur: 20,
          borderWidth: 1.2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                unselectedIcon: Icons.home_outlined,
                label: 'Home',
                activePillBg: activePillBg,
                activeBorderColor: activeBorderColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.calculate_rounded,
                unselectedIcon: Icons.calculate_outlined,
                label: 'Simulate',
                activePillBg: activePillBg,
                activeBorderColor: activeBorderColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.info_rounded,
                unselectedIcon: Icons.info_outline,
                label: 'Info',
                activePillBg: activePillBg,
                activeBorderColor: activeBorderColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.settings_rounded,
                unselectedIcon: Icons.settings_outlined,
                label: 'Settings',
                activePillBg: activePillBg,
                activeBorderColor: activeBorderColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    ),
      if (_isAppBlurred)
        const Positioned.fill(
          child: _SecurityProtectedOverlay(),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData unselectedIcon,
    required String label,
    required Color activePillBg,
    required Color activeBorderColor,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 72,
            height: 54,
            decoration: BoxDecoration(
              color: isSelected ? activePillBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? activeBorderColor : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isDark
                                ? const Color(0xFF818CF8)
                                : const Color(0xFF6366F1))
                            .withValues(alpha: isDark ? 0.22 : 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? icon : unselectedIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 21,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PIXEL-PERFECT "PAYWISE SECURITY PROTECTED" PRIVACY OVERLAY ──
class _SecurityProtectedOverlay extends StatelessWidget {
  const _SecurityProtectedOverlay();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0F1B) : const Color(0xFFF7F9FF);
    final textDark = isDark ? Colors.white : const Color(0xFF161C40);
    final textSub = isDark ? const Color(0xFFA0A7C2) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 36),

              // ── 1. TOP LOGO EMBLEM & BRAND TITLE ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Rounded Square Shield Emblem
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A36B1), Color(0xFF4C5BE3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B4CCA).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        // Shield Outline with Rupee & Check
                        Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        Positioned(
                          child: Text(
                            "₹",
                            style: TextStyle(
                              color: Color(0xFF2A36B1),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Brand Name (PayWise)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pay",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        "Wise",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B4CCA),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // ── 2. CENTER HERO SECURITY GRAPHIC ──
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Soft Aura Circle (250px)
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF3B4CCA).withValues(alpha: 0.06)
                            : const Color(0xFFEEF3FF),
                      ),
                    ),
                    // Inner Soft Aura Circle (190px)
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF3B4CCA).withValues(alpha: 0.12)
                            : const Color(0xFFF7F9FF),
                      ),
                    ),

                    // Floating Particle Accents
                    // Top Right Sparkle Star
                    const Positioned(
                      top: 45,
                      right: 48,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF4DD0E1),
                        size: 20,
                      ),
                    ),
                    // Top Right Blue Dot
                    Positioned(
                      top: 32,
                      right: 90,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8C9EFF).withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Left Mint Green Dot
                    Positioned(
                      left: 36,
                      top: 140,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF64FFDA).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Bottom Right Soft Indigo Dot
                    Positioned(
                      right: 40,
                      bottom: 80,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8C9EFF).withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Main Center 3D Gradient Shield Badge
                    Container(
                      width: 105,
                      height: 125,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5364F0), Color(0xFF3241C9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(52),
                          topRight: Radius.circular(52),
                          bottomLeft: Radius.circular(52),
                          bottomRight: Radius.circular(52),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B4CCA).withValues(alpha: 0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 3D Shield Outline Graphic
                          Icon(
                            Icons.shield_rounded,
                            size: 96,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          // White Checkmark Icon
                          const Icon(
                            Icons.check_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── 3. BOTTOM TITLE & DESCRIPTION ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Line 1: PayWise Security
                  Text(
                    "PayWise Security",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Title Line 2: Protected
                  const Text(
                    "Protected",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B4CCA),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pill Capsule Line Accent
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B4CCA)
                          : const Color(0xFFD4DCFA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Paragraph
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Your app is running securely in the background.\nWe're keeping your data safe.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSub,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
