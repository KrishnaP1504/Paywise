import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/theme/glass_theme.dart';
import 'package:paywise/widgets/undo_toast.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  const EmailVerificationScreen({super.key, required this.user});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _resendCooldown = 0;
  bool _isChecking = false;
  bool _isResending = false;
  bool _isApplyingCode = false;

  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Poll every 3 seconds to detect when the user verifies their email via the link
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkEmailVerified(auto: true);
    });
  }

  Future<void> _checkEmailVerified({bool auto = false}) async {
    if (_isChecking) return;
    if (!auto) setState(() => _isChecking = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        if (currentUser.emailVerified) {
          _pollingTimer?.cancel();
          if (mounted) {
            Provider.of<LoanProvider>(context, listen: false).initLoans();
            UndoToastManager.showSuccessToast(
              context: context,
              title: "Email Verified! 🎉",
              subtitle: "Your account is activated. Welcome to PayWise!",
            );
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          }
          return;
        }
      }
      if (!auto && mounted) {
        UndoToastManager.showInfoToast(
          context: context,
          title: "Not Yet Verified",
          subtitle: "Please click the link sent to ${widget.user.email} or enter your OTP code.",
        );
      }
    } catch (e) {
      debugPrint("Verification check notice: $e");
    } finally {
      if (!auto && mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _applyCode() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      UndoToastManager.showErrorToast(
        context: context,
        title: "Code Required",
        subtitle: "Please enter the verification code or OTP from your email.",
      );
      return;
    }

    setState(() => _isApplyingCode = true);
    try {
      await FirebaseAuth.instance.applyActionCode(code);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
      }
      _pollingTimer?.cancel();
      if (mounted) {
        Provider.of<LoanProvider>(context, listen: false).initLoans();
        UndoToastManager.showSuccessToast(
          context: context,
          title: "Code Verified! 🎉",
          subtitle: "Your email is confirmed. Welcome to PayWise!",
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        UndoToastManager.showErrorToast(
          context: context,
          title: "Invalid Code",
          subtitle: "The code entered is invalid or expired. You can also tap the link in your email.",
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingCode = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.sendEmailVerification();
        if (mounted) {
          UndoToastManager.showSuccessToast(
            context: context,
            title: "Verification Email Sent ✉️",
            subtitle: "A new activation link has been sent to ${widget.user.email}.",
          );
          setState(() {
            _resendCooldown = 60;
          });
          _cooldownTimer?.cancel();
          _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_resendCooldown <= 1) {
              timer.cancel();
              if (mounted) setState(() => _resendCooldown = 0);
            } else {
              if (mounted) setState(() => _resendCooldown--);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        UndoToastManager.showErrorToast(
          context: context,
          title: "Resend Failed",
          subtitle: "Please wait a moment before trying to resend.",
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _cancelAndSignOut() async {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    await _authService.signOut();
    if (mounted) {
      Provider.of<LoanProvider>(context, listen: false).clearUserData();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    _animController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const primaryNavy = Color(0xFF1E3C72);
    const accentIndigo = Color(0xFF3B4CCA);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _cancelAndSignOut,
          tooltip: "Back to Sign In",
        ),
      ),
      body: GlassBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(8, topPadding + kToolbarHeight + 10, 8, bottomPadding + 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── PULSING ICON BADGE ──
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentIndigo.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: "We sent an activation email to\n"),
                      TextSpan(
                        text: widget.user.email ?? "your email address",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : primaryNavy,
                        ),
                      ),
                      const TextSpan(
                        text: ".\nPlease check your inbox and tap the link to activate your account.",
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── CARD: PRIMARY ACTION BUTTONS ──
              Container(
                decoration: GlassTheme.cardDecoration(context, radius: 20),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Primary: I've Verified My Email
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3C72),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isChecking ? null : () => _checkEmailVerified(auto: false),
                        icon: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, size: 22),
                        label: Text(
                          _isChecking ? "Checking Status..." : "I've Verified My Email",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Resend Email Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (_resendCooldown > 0 || _isResending)
                            ? null
                            : _resendVerificationEmail,
                        icon: _isResending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          _resendCooldown > 0
                              ? "Resend Email in ${_resendCooldown}s"
                              : "Resend Verification Email",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── CARD: OR ENTER VERIFICATION / OTP CODE ──
              Container(
                decoration: GlassTheme.cardDecoration(context, radius: 20),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryNavy.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pin_rounded, size: 18, color: primaryNavy),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Have an OTP / Action Code?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "If you received a verification code in your email, you can paste or enter it here directly:",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        hintText: "Enter code from email",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF161926) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A5298),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isApplyingCode ? null : _applyCode,
                        child: _isApplyingCode
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Submit Code & Enter Dashboard",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cancel / Sign out
              TextButton.icon(
                onPressed: _cancelAndSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  "Use a Different Account",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
