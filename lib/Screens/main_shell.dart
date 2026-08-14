import 'package:flutter/material.dart';
import 'package:paywise/Screens/dashboard_screen.dart';
import 'package:paywise/Screens/simulation_screen.dart';
import 'package:paywise/Screens/info_screen.dart';
import 'package:paywise/Screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
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
        _previousIndex = _currentIndex;
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final activePillBg = isDark ? Colors.indigo.withValues(alpha: 0.3) : const Color(0xFFEEF0FD);
    final activeColor = isDark ? Colors.indigo[200]! : Colors.indigo[800]!;
    final inactiveColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final isForward = _currentIndex >= _previousIndex;
    final slideBeginOffset = isForward ? const Offset(0.08, 0) : const Offset(-0.08, 0);

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: slideBeginOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _pages[_currentIndex],
            ),
          ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: navBgColor,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                unselectedIcon: Icons.home_outlined,
                label: 'Home',
                activePillBg: activePillBg,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.calculate_rounded,
                unselectedIcon: Icons.calculate_outlined,
                label: 'Simulate',
                activePillBg: activePillBg,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.info_rounded,
                unselectedIcon: Icons.info_outline,
                label: 'Info',
                activePillBg: activePillBg,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.settings_rounded,
                unselectedIcon: Icons.settings_outlined,
                label: 'Settings',
                activePillBg: activePillBg,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
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
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? icon : unselectedIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
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
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Shield Outline with Rupee & Check
                        const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        const Positioned(
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
  }
}
