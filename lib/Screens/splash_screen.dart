import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _shimmerController;
  late final AnimationController _particleController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotate;
  late final Animation<double> _payOpacity;
  late final Animation<Offset> _paySlide;
  late final Animation<double> _wiseOpacity;
  late final Animation<Offset> _wiseSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _shimmerProgress;

  @override
  void initState() {
    super.initState();

    // ── Logo animation (0ms → 1200ms) ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // ── Text animation (400ms → 1400ms) ──
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _payOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _paySlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _wiseOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );
    _wiseSlide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Shimmer ring animation (loops) ──
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    // ── Floating particles animation (loops) ──
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // ── Sequence the animations ──
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    _shimmerController.repeat();

    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Wait for all animations to finish, then trigger onComplete
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0C1B) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background gradient glow ──
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Container(
                  width: 300 * _logoScale.value,
                  height: 300 * _logoScale.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3B4CCA).withValues(alpha: 0.08 * _logoOpacity.value),
                        const Color(0xFF3B4CCA).withValues(alpha: 0.02 * _logoOpacity.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Floating particles ──
          ...List.generate(8, (i) => _FloatingParticle(
            animation: _particleController,
            index: i,
            isDark: isDark,
          )),

          // ── Main content (centered) ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated Logo with shimmer ring ──
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _shimmerController]),
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _logoRotate.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value.clamp(0.0, 1.0),
                          child: SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Shimmer ring
                                if (_logoOpacity.value > 0.5)
                                  CustomPaint(
                                    size: const Size(160, 160),
                                    painter: _ShimmerRingPainter(
                                      progress: _shimmerProgress.value,
                                      color: const Color(0xFF3B4CCA),
                                    ),
                                  ),
                                // Logo image
                                Image.asset(
                                  'assets/images/paywise_logo.png',
                                  width: 135,
                                  height: 135,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 135,
                                    height: 135,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3B4CCA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 60,
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

                const SizedBox(height: 24),

                // ── Animated "Pay" + "Wise" title ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SlideTransition(
                          position: _paySlide,
                          child: Opacity(
                            opacity: _payOpacity.value.clamp(0.0, 1.0),
                            child: Text(
                              "Pay",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF161C40),
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ),
                        SlideTransition(
                          position: _wiseSlide,
                          child: Opacity(
                            opacity: _wiseOpacity.value.clamp(0.0, 1.0),
                            child: const Text(
                              "Wise",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3B4CCA),
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ── Animated tagline ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                      child: Text(
                        "Smart Loans, Smarter You",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFA0A7C2)
                              : const Color(0xFF6B7280),
                          letterSpacing: 0.4,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ── Loading indicator ──
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF3B4CCA).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Ring Painter ──
class _ShimmerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShimmerRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepAngle = pi / 3;
    final startAngle = 2 * pi * progress - pi / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Floating Particle Widget ──
class _FloatingParticle extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final bool isDark;

  const _FloatingParticle({
    required this.animation,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rng = Random.secure();
    final baseX = rng.nextDouble() * size.width;
    final baseY = rng.nextDouble() * size.height;
    final dotSize = 3.0 + rng.nextDouble() * 5;
    final amplitude = 12.0 + rng.nextDouble() * 18;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final dx = sin(progress * 2 * pi + index) * amplitude;
        final dy = cos(progress * 2 * pi + index * 0.7) * amplitude;

        return Positioned(
          left: baseX + dx,
          top: baseY + dy,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF3B4CCA).withValues(alpha: 0.15)
                  : const Color(0xFF3B4CCA).withValues(alpha: 0.1),
            ),
          ),
        );
      },
    );
  }
}
