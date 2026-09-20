import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized glassmorphism design system matching the floating bottom navbar:
/// Translucent specular surfaces, delicate frosted borders, ambient elevation,
/// and luminous ambient background glow.
class GlassTheme {
  /// Translucent frosted glass card decoration with specular reflection
  static BoxDecoration cardDecoration(
    BuildContext context, {
    double radius = 20,
    BorderRadius? customBorderRadius,
    Color? customBg,
    Border? customBorder,
    List<BoxShadow>? customShadow,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: customBg,
      gradient: customBg != null
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF242846).withValues(alpha: 0.68),
                      const Color(0xFF171A2E).withValues(alpha: 0.50),
                      const Color(0xFF0F1120).withValues(alpha: 0.38),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.60),
                    ],
            ),
      borderRadius: customBorderRadius ?? BorderRadius.circular(radius),
      border: customBorder ??
          Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.92),
            width: isDark ? 1.2 : 1.5,
          ),
      boxShadow: customShadow ??
          [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.48)
                  : const Color(0xFF4F46E5).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 3),
              spreadRadius: -2,
            ),
            if (isDark)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
    );
  }

  /// Translucent frosted glass button decoration with specular hairline edge
  /// and soft ambient colored glow (avoids overly bright/opaque neon appearance).
  static BoxDecoration buttonDecoration(
    BuildContext context, {
    Color? color,
    double radius = 16,
    bool isDanger = false,
    bool isSuccess = false,
    bool isSecondary = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color accent = isDanger
        ? const Color(0xFFDC2626)
        : isSuccess
            ? const Color(0xFF059669)
            : (color ?? (isDark ? const Color(0xFF6366F1) : const Color(0xFF1E3C72)));

    if (isSecondary) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF262A44).withValues(alpha: 0.55),
                  const Color(0xFF171A2E).withValues(alpha: 0.35),
                ]
              : [
                  Colors.white.withValues(alpha: 0.65),
                  const Color(0xFFF1F5F9).withValues(alpha: 0.45),
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.10),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                accent.withValues(alpha: 0.46),
                accent.withValues(alpha: 0.26),
              ]
            : [
                accent.withValues(alpha: 0.90),
                accent.withValues(alpha: 0.78),
              ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.26)
            : Colors.white.withValues(alpha: 0.65),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : accent.withValues(alpha: 0.20),
          blurRadius: 14,
          offset: const Offset(0, 5),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
          blurRadius: 16,
          offset: const Offset(0, 3),
        ),
        if (isDark)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
      ],
    );
  }

  /// Glassy button style helper for standard ElevatedButton/OutlinedButton
  static ButtonStyle glassButtonStyle(
    BuildContext context, {
    Color? color,
    double radius = 14,
    bool isDanger = false,
    bool isSuccess = false,
    bool isSecondary = false,
    EdgeInsetsGeometry? padding,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = isDanger
        ? const Color(0xFFDC2626)
        : isSuccess
            ? const Color(0xFF059669)
            : (color ?? (isDark ? const Color(0xFF6366F1) : const Color(0xFF1E3C72)));

    final Color bg = isSecondary
        ? (isDark
            ? const Color(0xFF262A44).withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.55))
        : (isDark
            ? accent.withValues(alpha: 0.38)
            : accent.withValues(alpha: 0.88));

    final Color borderCol = isDark
        ? (isSecondary
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.26))
        : (isSecondary
            ? Colors.black.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.60));

    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: isSecondary
          ? (isDark ? Colors.white : const Color(0xFF1E293B))
          : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderCol, width: 1.1),
      ),
    );
  }

  /// Frosted glass gradient card decoration (for Hero cards, headers, summaries)
  static BoxDecoration gradientCardDecoration(
    BuildContext context, {
    required List<Color> colors,
    double radius = 24,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    Color? shadowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors.map((c) => c.withValues(alpha: isDark ? 0.84 : 0.90)).toList(),
        begin: begin,
        end: end,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: isDark ? 0.30 : 0.45),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (shadowColor ?? colors.first).withValues(alpha: isDark ? 0.45 : 0.32),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.20),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }


  /// Translucent badge/pill decoration (e.g. "Active", "Completed", "EMI Due")
  static BoxDecoration pillDecoration(
    BuildContext context, {
    required Color color,
    double radius = 10,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.24 : 0.12),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color.withValues(alpha: isDark ? 0.48 : 0.32),
        width: 1.2,
      ),
    );
  }

  /// Soft glassy icon container background
  static BoxDecoration iconBoxDecoration(
    BuildContext context, {
    Color color = Colors.indigo,
    double radius = 14,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color.withValues(alpha: isDark ? 0.40 : 0.25),
        width: 1.2,
      ),
    );
  }

  /// Creates an Apple-inspired frosted glass flexibleSpace for AppBars.
  /// When paired with Scaffold(extendBodyBehindAppBar: true), content scrolling
  /// underneath will be optically blurred with specular translucency and an adaptive hairline edge.
  ///
  /// If [isScrolledNotifier] is provided, it automatically subscribes to scroll state
  /// to seamlessly show/hide the bottom border line only when scrolled away from top.
  static Widget frostedAppBarFlexibleSpace(
    BuildContext context, {
    ValueNotifier<bool>? isScrolledNotifier,
    double blur = 20,
    double? opacity,
    bool isScrolled = false,
  }) {
    if (isScrolledNotifier != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: isScrolledNotifier,
        builder: (context, scrolled, _) {
          return frostedAppBarFlexibleSpace(
            context,
            blur: blur,
            opacity: opacity,
            isScrolled: scrolled,
          );
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOpacity = opacity ?? (isDark ? 0.70 : 0.75);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0C0E17).withValues(alpha: effectiveOpacity)
                : Colors.white.withValues(alpha: effectiveOpacity),
            border: Border(
              bottom: BorderSide(
                color: isScrolled
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.08))
                    : Colors.transparent,
                width: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted glass dialog decoration for glassy popups
  static BoxDecoration dialogDecoration(
    BuildContext context, {
    double radius = 24,
    BorderRadiusGeometry? customRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = customRadius ?? BorderRadius.circular(radius);

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF1E2238).withValues(alpha: 0.74),
                const Color(0xFF131525).withValues(alpha: 0.58),
                const Color(0xFF0C0E18).withValues(alpha: 0.45),
              ]
            : [
                Colors.white.withValues(alpha: 0.80),
                const Color(0xFFF8FAFC).withValues(alpha: 0.62),
                const Color(0xFFEEF2F6).withValues(alpha: 0.48),
              ],
      ),
      borderRadius: effectiveRadius,
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.95),
        width: isDark ? 1.4 : 1.6,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.60)
              : const Color(0xFF0F172A).withValues(alpha: 0.16),
          blurRadius: 40,
          offset: const Offset(0, 18),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.20)
              : const Color(0xFF3B82F6).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.85),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Frosted glass bottom sheet decoration with top rounded corners and glassy styling
  static BoxDecoration bottomSheetDecoration(
    BuildContext context, {
    double radius = 24,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF1E2238).withValues(alpha: 0.85),
                const Color(0xFF131525).withValues(alpha: 0.75),
                const Color(0xFF0C0E18).withValues(alpha: 0.70),
              ]
            : [
                Colors.white.withValues(alpha: 0.90),
                const Color(0xFFF8FAFC).withValues(alpha: 0.82),
                const Color(0xFFEEF2F6).withValues(alpha: 0.75),
              ],
      ),
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.98),
          width: 1.6,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.55)
              : const Color(0xFF0F172A).withValues(alpha: 0.16),
          blurRadius: 40,
          offset: const Offset(0, -8),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.18)
              : const Color(0xFF3B82F6).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  /// Helper to display a glassy alert dialog with BackdropFilter blur and smooth entrance
  static Future<T?> showGlassDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.42)
          : const Color(0xFF0F172A).withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => builder(ctx),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// A scroll wrapper that automatically tracks scroll offset and notifies
/// whether the scroll position has departed from the top.
class ScrolledNotificationWrapper extends StatelessWidget {
  final ValueNotifier<bool> isScrolledNotifier;
  final Widget child;
  final double threshold;

  const ScrolledNotificationWrapper({
    super.key,
    required this.isScrolledNotifier,
    required this.child,
    this.threshold = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          final scrolled = notification.metrics.pixels > threshold;
          if (isScrolledNotifier.value != scrolled) {
            isScrolledNotifier.value = scrolled;
          }
        }
        return false;
      },
      child: child,
    );
  }
}

/// Ambient background widget that radiates subtle glowing aurora orbs.
/// This provides the visual depth that allows translucent frosted cards
/// to genuinely "feel" and look like real glass in both light and dark modes.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F111E), // Deep midnight indigo slate
                  Color(0xFF090A12), // Cosmic obsidian
                  Color(0xFF0C0E19), // Deep twilight navy
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFEDF2F7),
                ],
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Top-right radiant Indigo/Electric-Blue Orb
          Positioned(
            top: -40,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF4F46E5).withValues(alpha: 0.32),
                            const Color(0xFF3730A3).withValues(alpha: 0.14),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF818CF8).withValues(alpha: 0.28),
                            const Color(0xFF818CF8).withValues(alpha: 0.0),
                          ],
                  ),
                ),
              ),
            ),
          ),
          // 2. Upper-left subtle Cyan Aurora Orb
          Positioned(
            top: 120,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF06B6D4).withValues(alpha: 0.18),
                            const Color(0xFF0284C7).withValues(alpha: 0.08),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF38BDF8).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),
          // 3. Mid-right Luminous Violet Aurora Orb
          Positioned(
            top: 360,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF7C3AED).withValues(alpha: 0.20),
                            const Color(0xFF6D28D9).withValues(alpha: 0.08),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFFC084FC).withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),
          // 4. Lower-left Emerald/Teal Subtle Ambient Glow Orb
          Positioned(
            bottom: 140,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF059669).withValues(alpha: 0.15),
                            const Color(0xFF0D9488).withValues(alpha: 0.05),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF34D399).withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),
          // 5. Bottom-right Deep Indigo Orb
          Positioned(
            bottom: -50,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF4338CA).withValues(alpha: 0.24),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFF818CF8).withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),
          // Child content
          child,
        ],
      ),
    );
  }
}

/// A production-ready, Apple-inspired frosted glass container.
/// Combines optical diffusion (BackdropFilter), specular surface reflectance
/// (linear gradient), hairline bevel border (1px translucent edge), and
/// diffused ambient drop shadows.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double borderWidth;
  final Color? borderColor;
  final Gradient? gradient;
  final Color? surfaceColor;
  final List<BoxShadow>? shadows;
  final bool enableBlur;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 22.0,
    this.blur = 18.0,
    this.borderWidth = 1.0,
    this.borderColor,
    this.gradient,
    this.surfaceColor,
    this.shadows,
    this.enableBlur = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Apple-spec default border: Hairline specular highlight
    final defaultBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.85));

    // 2. Apple-spec surface gradient: Specular top-left to diffused bottom-right
    final defaultGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF232538).withValues(alpha: 0.75),
                  const Color(0xFF141624).withValues(alpha: 0.52),
                ]
              : [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.50),
                ],
        );

    // 3. Apple-spec dual soft ambient shadows
    final effectiveShadows = shadows ??
        [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF3B4261).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

    Widget body = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      body = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: body,
        ),
      );
    }

    Widget glassSurface = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: surfaceColor,
        gradient: surfaceColor == null ? defaultGradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth > 0
            ? Border.all(
                color: defaultBorderColor,
                width: borderWidth,
              )
            : null,
      ),
      child: body,
    );

    Widget frosted;
    if (enableBlur && blur > 0) {
      frosted = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: glassSurface,
        ),
      );
    } else {
      frosted = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: glassSurface,
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: effectiveShadows,
        ),
        child: frosted,
      ),
    );
  }
}

/// Universal frosted glass popup dialog with real-time optical blur and luminous specular highlights
class GlassAlertDialog extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsets? insetPadding;
  final double radius;
  final double blur;

  const GlassAlertDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.insetPadding,
    this.radius = 24,
    this.blur = 26,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.none,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: GlassTheme.dialogDecoration(context, radius: radius),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // Specular Light Flares
                _buildGlowOrb(
                  top: -40,
                  left: -40,
                  size: 160,
                  colors: isDark
                      ? [
                          const Color(0xFF818CF8).withValues(alpha: 0.25),
                          const Color(0xFF6366F1).withValues(alpha: 0.08),
                          Colors.transparent,
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.85),
                          const Color(0xFF60A5FA).withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                ),
                _buildGlowOrb(
                  bottom: -45,
                  right: -45,
                  size: 140,
                  colors: isDark
                      ? [
                          const Color(0xFF38BDF8).withValues(alpha: 0.16),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFF818CF8).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                ),
                // 3. Top Specular Bevel Rim Highlight (VisionOS style light catching upper edge)
                Positioned(
                  top: 0,
                  left: radius * 0.4,
                  right: radius * 0.4,
                  height: 1.5,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: isDark ? 0.65 : 0.95),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 4. Content
                Padding(
                  padding: contentPadding ?? const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        Center(child: icon!),
                        const SizedBox(height: 14),
                      ],
                      if (title != null) ...[
                        DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color ??
                                (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          textAlign: TextAlign.center,
                          child: title!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (content != null) ...[
                        Flexible(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                            child: content!,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (actions != null && actions!.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions!.map((a) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: a,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildGlowOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required List<Color> colors,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

/// A premium frosted glass button with optical blur, specular reflection,
/// ambient glow, and translucent tinted glass surface.
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final Color? color;
  final double radius;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool isSecondary;
  final bool isDanger;
  final bool isSuccess;
  final bool isLoading;
  final double fontSize;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.color,
    this.radius = 16,
    this.width,
    this.height = 48,
    this.padding,
    this.isSecondary = false,
    this.isDanger = false,
    this.isSuccess = false,
    this.isLoading = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    final decoration = GlassTheme.buttonDecoration(
      context,
      color: color,
      radius: radius,
      isDanger: isDanger,
      isSuccess: isSuccess,
      isSecondary: isSecondary,
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.55,
      child: Container(
        width: width,
        height: height,
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [
                // Top Specular Bevel Rim Highlight (VisionOS style reflection)
                Positioned(
                  top: 0,
                  left: radius * 0.3,
                  right: radius * 0.3,
                  height: 1.2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: isDark ? 0.45 : 0.70),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? onPressed : null,
                    borderRadius: BorderRadius.circular(radius),
                    splashColor: Colors.white.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.06),
                    child: Padding(
                      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (icon != null) ...[
                                    icon!,
                                    const SizedBox(width: 8),
                                  ],
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      color: isSecondary
                                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSize,
                                      letterSpacing: 0.3,
                                    ),
                                    child: child,
                                  ),
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
      ),
    );
  }
}

