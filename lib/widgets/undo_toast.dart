import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/main.dart';

class UndoToastManager {
  static OverlayEntry? _currentOverlay;
  static Timer? _undoTimer;
  static Timer? _toastTimer;

  static OverlayState? _getOverlayState(BuildContext context) {
    if (navigatorKey.currentState?.overlay != null) {
      return navigatorKey.currentState!.overlay;
    }
    if (context.mounted) {
      return Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    }
    return null;
  }

  static double _calcBottom(BuildContext ctx) {
    final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
    final paddingBottom = MediaQuery.of(ctx).padding.bottom;
    return viewInsets > 0 ? (viewInsets + 16) : (paddingBottom + 90);
  }

  // ── 1. UNDO DELETE TOAST (POPUP FROM BOTTOM ABOVE NAVBAR) ──
  static void showUndoDeleteToast({
    required BuildContext context,
    required LoanModel loan,
  }) {
    _undoTimer?.cancel();
    _dismissOverlay();

    final overlayState = _getOverlayState(context);
    if (overlayState == null) return;

    final safeCtx = navigatorKey.currentContext ?? (context.mounted ? context : null);
    if (safeCtx == null) return;

    final loanProvider = Provider.of<LoanProvider>(safeCtx, listen: false);
    loanProvider.stageLoanForDeletion(loan);

    bool isUndone = false;

    // 8-Second Count-down Timer
    _undoTimer = Timer(const Duration(seconds: 8), () async {
      if (!isUndone) {
        _dismissOverlay();
        try {
          await loanProvider.confirmPermanentDelete(loan.id);
        } catch (e) {
          final targetCtx = navigatorKey.currentContext ?? (context.mounted ? context : null);
          if (targetCtx != null && targetCtx.mounted) {
            showErrorToast(
              context: targetCtx,
              title: "${loan.lenderName.isNotEmpty ? loan.lenderName : loan.category} Loan could not be deleted",
              subtitle: "Please try again later.",
            );
          }
          loanProvider.cancelStageLoanDeletion(loan);
        }
      }
    });

    _currentOverlay = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          bottom: _calcBottom(ctx),
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _BaseToastWidget(
              title: "${loan.lenderName.isNotEmpty ? loan.lenderName : loan.category} Loan deleted",
              subtitle: "Loan removed from your list.",
              icon: Icons.delete_outline_rounded,
              brandColor: const Color(0xFF6C5CE7),
              lightBgColor: const Color(0xFFF3F0FF),
              darkBgColor: const Color(0xFF221C38),
              actionLabel: "Undo",
              onAction: () {
                isUndone = true;
                _undoTimer?.cancel();
                loanProvider.cancelStageLoanDeletion(loan);
                _dismissOverlay();
              },
              onClose: () {
                _dismissOverlay();
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(_currentOverlay!);
  }

  static void _showToast({
    required BuildContext context,
    required _BaseToastWidget widget,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _dismissOverlay();

    final overlayState = _getOverlayState(context);
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          bottom: _calcBottom(ctx),
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: widget,
          ),
        );
      },
    );

    overlayState.insert(entry);
    _currentOverlay = entry;

    _toastTimer = Timer(duration, () {
      if (_currentOverlay == entry) {
        _dismissOverlay();
      }
    });
  }

  // ── 2. SUCCESS SAVED TOAST (POPUP FROM BOTTOM ABOVE NAVBAR) ──
  static void showSuccessToast({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    _showToast(
      context: context,
      widget: _BaseToastWidget(
        title: title,
        subtitle: subtitle,
        icon: Icons.check_rounded,
        iconSize: 22,
        brandColor: const Color(0xFF10B981),
        lightBgColor: const Color(0xFFECFDF5),
        darkBgColor: const Color(0xFF14382B),
        lightTitleColor: const Color(0xFF065F46),
        lightSubtitleColor: const Color(0xFF047857),
        darkSubtitleColor: const Color(0xFFA7F3D0),
        onClose: _dismissOverlay,
      ),
    );
  }

  // ── 3. ERROR TOAST (POPUP FROM BOTTOM ABOVE NAVBAR) ──
  static void showErrorToast({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    _showToast(
      context: context,
      duration: const Duration(seconds: 4),
      widget: _BaseToastWidget(
        title: title,
        subtitle: subtitle,
        icon: Icons.error_outline_rounded,
        brandColor: const Color(0xFFDC2626),
        lightBgColor: const Color(0xFFFDF2F2),
        darkBgColor: const Color(0xFF3B1C1C),
        lightTitleColor: const Color(0xFF991B1B),
        lightSubtitleColor: const Color(0xFFB91C1C),
        darkTitleColor: const Color(0xFFFECDD3),
        darkSubtitleColor: const Color(0xFFFCA5A5),
        onClose: _dismissOverlay,
      ),
    );
  }

  // ── 4. INFO TOAST (POPUP FROM BOTTOM ABOVE NAVBAR) ──
  static void showInfoToast({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    _showToast(
      context: context,
      widget: _BaseToastWidget(
        title: title,
        subtitle: subtitle,
        icon: Icons.info_outline_rounded,
        iconSize: 22,
        brandColor: const Color(0xFF6C5CE7),
        lightBgColor: const Color(0xFFF5F3FF),
        darkBgColor: const Color(0xFF231C38),
        lightTitleColor: const Color(0xFF4C1D95),
        lightSubtitleColor: const Color(0xFF6D28D9),
        darkTitleColor: const Color(0xFFEDE9FE),
        darkSubtitleColor: const Color(0xFFDDD6FE),
        onClose: _dismissOverlay,
      ),
    );
  }

  static void _dismissOverlay() {
    _toastTimer?.cancel();
    _toastTimer = null;
    try {
      _currentOverlay?.remove();
    } catch (_) {}
    _currentOverlay = null;
  }
}

// ── PARAMETERIZED ANIMATED TOAST WIDGET (SLIDES UP FROM BOTTOM) ──
class _BaseToastWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double iconSize;
  final Color brandColor;
  final Color lightBgColor;
  final Color darkBgColor;
  final Color? lightTitleColor;
  final Color? darkTitleColor;
  final Color? lightSubtitleColor;
  final Color? darkSubtitleColor;
  final VoidCallback onClose;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _BaseToastWidget({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconSize = 20,
    required this.brandColor,
    required this.lightBgColor,
    required this.darkBgColor,
    this.lightTitleColor,
    this.darkTitleColor,
    this.lightSubtitleColor,
    this.darkSubtitleColor,
    required this.onClose,
    this.onAction,
    this.actionLabel,
  });

  @override
  State<_BaseToastWidget> createState() => _BaseToastWidgetState();
}

class _BaseToastWidgetState extends State<_BaseToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? widget.darkBgColor : widget.lightBgColor;
    final titleColor = isDark
        ? (widget.darkTitleColor ?? Colors.white)
        : (widget.lightTitleColor ?? const Color(0xFF1E1B4B));
    final subtitleColor = isDark
        ? (widget.darkSubtitleColor ?? const Color(0xFFA5B4FC))
        : (widget.lightSubtitleColor ?? const Color(0xFF6B7280));

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.brandColor.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: widget.brandColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular Icon Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.brandColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.iconSize,
                ),
              ),

              const SizedBox(width: 12),

              // Title & Subtitle Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (widget.onAction != null && widget.actionLabel != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      widget.actionLabel!,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: widget.brandColor,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 18,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                ),
              ] else
                const SizedBox(width: 8),

              // Close Button
              InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    color: subtitleColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
