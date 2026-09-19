import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/theme/glass_theme.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _promptPasswordAndExecute({
    required String actionTitle,
    required String confirmText,
    required Future<void> Function(String password) onVerified,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');

    // ── 1. GOOGLE SIGN-IN USERS: RE-AUTHENTICATE WITH GOOGLE ──
    if (isGoogleUser) {
      String? errorMessage;
      bool isVerifying = false;

      await GlassTheme.showGlassDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return GlassAlertDialog(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFDC2626), size: 34),
                ),
                title: Text(actionTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You signed in using your Google Account (${user.email ?? 'Google User'}).",
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Please verify your Google identity to confirm deletion.",
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isVerifying ? null : () => Navigator.pop(dialogCtx),
                    child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isVerifying
                        ? null
                        : () async {
                            setDialogState(() {
                              isVerifying = true;
                              errorMessage = null;
                            });

                            try {
                              await _authService.reauthenticateWithGoogle();
                              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                              await onVerified("");
                            } catch (e) {
                              setDialogState(() {
                                isVerifying = false;
                                errorMessage = "Google verification failed: ${e.toString()}";
                              });
                            }
                          },
                    icon: isVerifying
                        ? const SizedBox.shrink()
                        : const Icon(Icons.verified_user_outlined, size: 18, color: Colors.white),
                    label: isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Verify with Google", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    // ── 2. EMAIL / PASSWORD USERS: RE-AUTHENTICATE WITH PASSWORD ──
    final passwordController = TextEditingController();
    bool obscureText = true;
    String? errorMessage;
    bool isVerifying = false;

    await GlassTheme.showGlassDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return GlassAlertDialog(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_outlined, color: Color(0xFFDC2626), size: 28),
              ),
              title: Text(actionTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please enter your account password to confirm deletion.",
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: "Account Password",
                      hintText: "Enter your password",
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2A36B1)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setDialogState(() => obscureText = !obscureText);
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(dialogCtx),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            setDialogState(() => errorMessage = "Password cannot be empty");
                            return;
                          }

                          setDialogState(() {
                            isVerifying = true;
                            errorMessage = null;
                          });

                          try {
                            await _authService.reauthenticateWithPassword(password);
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            await onVerified(password);
                          } catch (e) {
                            setDialogState(() {
                              isVerifying = false;
                              errorMessage = "Incorrect password. Please try again.";
                            });
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleDeletion7Days() async {
    await _promptPasswordAndExecute(
      actionTitle: "Schedule Deletion (7 Days)",
      confirmText: "Schedule Deletion",
      onVerified: (password) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        setState(() => _isLoading = true);
        try {
          await _authService.scheduleAccountDeletion(user.uid);
          await _authService.signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenWelcome', false);
          if (mounted) {
            Provider.of<LoanProvider>(context, listen: false).clearUserData();
            Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            UndoToastManager.showSuccessToast(
              context: context,
              title: "Deletion Scheduled (7 Days)",
              subtitle: "You can restore your account by logging in within 7 days.",
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            UndoToastManager.showErrorToast(
              context: context,
              title: "Action Failed",
              subtitle: e.toString(),
            );
          }
        }
      },
    );
  }

  Future<void> _confirmImmediateDeletion() async {
    await _promptPasswordAndExecute(
      actionTitle: "Delete Permanently Now",
      confirmText: "Delete Now",
      onVerified: (password) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        setState(() => _isLoading = true);
        try {
          await _authService.purgeUserDataAndAccount(user.uid, password: password);
          await _authService.signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenWelcome', false);
          if (mounted) {
            Provider.of<LoanProvider>(context, listen: false).clearUserData();
            Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            UndoToastManager.showSuccessToast(
              context: context,
              title: "Account Permanently Deleted",
              subtitle: "All your data has been completely erased.",
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            UndoToastManager.showErrorToast(
              context: context,
              title: "Deletion Failed",
              subtitle: e.toString().contains("requires-recent-login")
                  ? "Please log out and log back in to verify account deletion."
                  : e.toString(),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final brandIndigo = isDark ? const Color(0xFF818CF8) : const Color(0xFF2A36B1);

    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "Your Account";

    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 10;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Delete Account",
          style: TextStyle(
            color: titleColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GlassBackground(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFDC2626)),
                    SizedBox(height: 16),
                    Text("Processing Account Deletion...", style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(8.0, totalTopPadding, 8.0, 40.0),
              child: Column(
                children: [
                  // Top Red Shield Icon Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFDC2626),
                      size: 38,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "We're sorry to see you go",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: brandIndigo,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Information Card (7-Day Grace Window Details)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: GlassTheme.cardDecoration(context, radius: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: brandIndigo, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              "How Account Deletion Works",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildInfoBullet(
                          icon: Icons.timer_outlined,
                          title: "7-Day Grace Period",
                          description:
                              "When you schedule deletion, your account is queued for 7 days. Your identity and data remain safe during this window.",
                          subtextColor: subtextColor,
                          titleColor: titleColor,
                        ),
                        const SizedBox(height: 14),
                        _buildInfoBullet(
                          icon: Icons.restore_rounded,
                          title: "Easy 1-Tap Recovery",
                          description:
                              "Changed your mind? Simply log back in with your email within 7 days to immediately cancel deletion and restore your loans.",
                          subtextColor: subtextColor,
                          titleColor: titleColor,
                        ),
                        const SizedBox(height: 14),
                        _buildInfoBullet(
                          icon: Icons.cleaning_services_rounded,
                          title: "Permanent Data Wipe After 7 Days",
                          description:
                              "After 7 days, your email, profile, loans, schedules, and active settings will be permanently erased from our servers forever.",
                          subtextColor: subtextColor,
                          titleColor: titleColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Option 1: Schedule Deletion (7-Day Grace Period)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: brandIndigo, width: 1.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _scheduleDeletion7Days,
                      icon: Icon(Icons.schedule_rounded, color: brandIndigo),
                      label: Text(
                        "Schedule Deletion (7-Day Grace Period)",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: brandIndigo,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Option 2: Delete Permanently Now
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _confirmImmediateDeletion,
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                      label: const Text(
                        "Delete Permanently Now (No Waiting)",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildInfoBullet({
    required IconData icon,
    required String title,
    required String description,
    required Color titleColor,
    required Color subtextColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bulletBg = isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEEF2FF);
    final bulletIconColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF2A36B1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bulletBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: bulletIconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
