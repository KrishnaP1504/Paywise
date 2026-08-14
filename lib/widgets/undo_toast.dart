import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paywise/models/loan_model.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/main.dart';

class UndoToastManager {
  static OverlayEntry? _currentOverlay;
  static Timer? _undoTimer;

  static OverlayState? _getOverlayState(BuildContext context) {
    if (navigatorKey.currentState?.overlay != null) {
      return navigatorKey.currentState!.overlay;
    }
    if (context.mounted) {
      return Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    }
    return null;
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
          final errOverlay = _getOverlayState(context);
          if (errOverlay != null) {
            showErrorToast(
              context: context,
              title: "${loan.lenderName.isNotEmpty ? loan.lenderName : loan.category} Loan could not be deleted",
              subtitle: "Please try again later.",
            );
            loanProvider.cancelStageLoanDeletion(loan);
          }
        }
      }
    });

    _currentOverlay = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          bottom: MediaQuery.of(ctx).padding.bottom + 90,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _UndoToastWidget(
              title: "${loan.lenderName.isNotEmpty ? loan.lenderName : loan.category} Loan deleted",
              subtitle: "Loan removed from your list.",
              onUndo: () {
                isUndone = true;
                _undoTimer?.cancel();
                loanProvider.cancelStageLoanDeletion(loan);
                _dismissOverlay();
              },
              onClose: () async {
                isUndone = true;
                _undoTimer?.cancel();
                _dismissOverlay();
                try {
                  await loanProvider.confirmPermanentDelete(loan.id);
                } catch (e) {
                  showErrorToast(
                    context: context,
                    title: "${loan.lenderName.isNotEmpty ? loan.lenderName : loan.category} Loan could not be deleted",
                    subtitle: "Please try again later.",
                  );
                  loanProvider.cancelStageLoanDeletion(loan);
                }
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(_currentOverlay!);
  }

  // ── 2. SUCCESS SAVED TOAST (POPUP FROM BOTTOM ABOVE NAVBAR) ──
  static void showSuccessToast({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    _dismissOverlay();

    final overlayState = _getOverlayState(context);
    if (overlayState == null) return;

    late OverlayEntry successEntry;

    successEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          bottom: MediaQuery.of(ctx).padding.bottom + 90,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _SuccessToastWidget(
              title: title,
              subtitle: subtitle,
              onClose: () {
                try {
                  successEntry.remove();
                } catch (_) {}
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(successEntry);
    _currentOverlay = successEntry;

    Timer(const Duration(milliseconds: 3500), () {
      try {
        if (_currentOverlay == successEntry) {
          successEntry.remove();
          _currentOverlay = null;
        }
      } catch (_) {}
    });
  }

  // ── 3. ERROR TOAST (POPUP FROM BOTTOM ABOVE NAVBAR) ──
  static void showErrorToast({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    _dismissOverlay();

    final overlayState = _getOverlayState(context);
    if (overlayState == null) return;
    late OverlayEntry errorEntry;

    errorEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          bottom: MediaQuery.of(ctx).padding.bottom + 90,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _ErrorToastWidget(
              title: title,
              subtitle: subtitle,
              onClose: () {
                try {
                  errorEntry.remove();
                } catch (_) {}
              },
            ),
          ),
        );
      },
    );

    overlayState.insert(errorEntry);
    _currentOverlay = errorEntry;

    Timer(const Duration(seconds: 4), () {
      try {
        if (_currentOverlay == errorEntry) {
          errorEntry.remove();
          _currentOverlay = null;
        }
      } catch (_) {}
    });
  }

  static void _dismissOverlay() {
    try {
      _currentOverlay?.remove();
    } catch (_) {}
    _currentOverlay = null;
  }
}

// ── UNDO TOAST WIDGET (SLIDES UP FROM BOTTOM) ──
class _UndoToastWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUndo;
  final VoidCallback onClose;

  const _UndoToastWidget({
    required this.title,
    required this.subtitle,
    required this.onUndo,
    required this.onClose,
  });

  @override
  State<_UndoToastWidget> createState() => _UndoToastWidgetState();
}

class _UndoToastWidgetState extends State<_UndoToastWidget>
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
    const purpleBrand = Color(0xFF6C5CE7);
    final bgColor = isDark ? const Color(0xFF221C38) : const Color(0xFFF3F0FF);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final subtitleColor = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6B7280);

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
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: purpleBrand.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular Trash Icon Badge
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: purpleBrand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
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
                      maxLines: 1,
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
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Undo Button
              InkWell(
                onTap: widget.onUndo,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "Undo",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: purpleBrand,
                    ),
                  ),
                ),
              ),

              // Divider
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
              ),

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

// ── REDESIGNED SUCCESS TOAST WIDGET (SLIDES UP FROM BOTTOM) ──
class _SuccessToastWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _SuccessToastWidget({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  State<_SuccessToastWidget> createState() => _SuccessToastWidgetState();
}

class _SuccessToastWidgetState extends State<_SuccessToastWidget>
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
    const greenBrand = Color(0xFF10B981);
    final bgColor = isDark ? const Color(0xFF14382B) : const Color(0xFFECFDF5);
    final titleColor = isDark ? Colors.white : const Color(0xFF065F46);
    final subtitleColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857);

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
                color: greenBrand.withValues(alpha: isDark ? 0.3 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: greenBrand.withValues(alpha: isDark ? 0.4 : 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular Checkmark Badge
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: greenBrand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 22,
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
                      maxLines: 1,
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
                    ),
                  ],
                ),
              ),

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

// ── ERROR TOAST WIDGET (SLIDES UP FROM BOTTOM) ──
class _ErrorToastWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _ErrorToastWidget({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  State<_ErrorToastWidget> createState() => _ErrorToastWidgetState();
}

class _ErrorToastWidgetState extends State<_ErrorToastWidget>
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
    const redBrand = Color(0xFFDC2626);
    final bgColor = isDark ? const Color(0xFF3B1C1C) : const Color(0xFFFDF2F2);
    final titleColor = isDark ? const Color(0xFFFECDD3) : const Color(0xFF991B1B);
    final subtitleColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);

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
                color: Colors.red.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: redBrand.withValues(alpha: isDark ? 0.4 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular Warning Icon Badge
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: redBrand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
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
                      maxLines: 1,
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
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Close Button
              InkWell(
                onTap: widget.onClose,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    color: titleColor,
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
