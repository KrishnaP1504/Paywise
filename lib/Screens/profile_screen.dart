import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/services/notification_service.dart';
import 'package:paywise/Screens/delete_account_screen.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/theme/glass_theme.dart';
import 'package:paywise/Screens/edit_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);
  String? _customUsername;

  @override
  void initState() {
    super.initState();
    _loadCustomUsername();
  }

  Future<void> _loadCustomUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        if (profile['username'] != null && (profile['username'] as String).isNotEmpty) {
          if (mounted) {
            setState(() {
              _customUsername = profile['username'];
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  void _confirmLogout() {
    GlassTheme.showGlassDialog(
      context: context,
      builder: (ctx) {
        return GlassAlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 28),
          ),
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out of your PayWise account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
            GlassButton(
              height: 38,
              radius: 12,
              isDanger: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await _authService.signOut();
                if (mounted) {
                  Provider.of<LoanProvider>(context, listen: false).clearUserData();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: const Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditInfo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditInfoScreen()),
    );
    if (result == true || mounted) {
      await _loadCustomUsername();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final photoURL = user?.photoURL;
    final phoneNumber = user?.phoneNumber;
    final email = user?.email;
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (email?.split('@').first ?? "User");

    // Exact Deep Navy Blue Palette matching Dashboard Total Outstanding Card
    const primaryNavy = Color(0xFF1E3C72);
    const primaryNavyLight = Color(0xFF2A5298);
    final iconBoxBgColor = isDark ? primaryNavy.withValues(alpha: 0.25) : const Color(0xFFEBF1F9);
    final sectionTextColor = isDark ? const Color(0xFF90B3E8) : primaryNavy;

    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Profile & Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
      ),
      body: GlassBackground(
        child: ScrolledNotificationWrapper(
          isScrolledNotifier: _isScrolled,
          child: ListView(
          padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 150),
          children: [
            // ── 1. TELEGRAM / APPLE HIG PROFILE HEADER ──
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [primaryNavy, primaryNavyLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.90),
                            width: 3.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryNavy.withValues(alpha: isDark ? 0.40 : 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: (photoURL != null && photoURL.isNotEmpty)
                              ? Image.network(
                                  photoURL,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Camera / Edit Badge in bottom-right corner
                      GestureDetector(
                        onTap: _navigateToEditInfo,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF0C0E17) : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final displayHandle = _customUsername != null && _customUsername!.isNotEmpty
                          ? _customUsername!
                          : displayName.toLowerCase().replaceAll(' ', '');
                      return Text(
                        (phoneNumber != null && phoneNumber.isNotEmpty)
                            ? "$phoneNumber • @$displayHandle"
                            : ((email != null && email.isNotEmpty)
                                ? "@$displayHandle • $email"
                                : "@$displayHandle"),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // ── 2. APP SETTINGS SECTION ──
          Row(
            children: [
              const Icon(Icons.settings_outlined, color: primaryNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                "App Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: sectionTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: GlassTheme.cardDecoration(context, radius: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Dark Mode Switch
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      onTap: () => settings.toggleTheme(!isDark),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBoxBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isDark ? Icons.nightlight_round : Icons.dark_mode_outlined,
                          color: isDark ? Colors.amber : primaryNavy,
                        ),
                      ),
                      title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(
                        settings.isThemeSystem
                            ? "Following phone theme (${isDark ? 'Dark' : 'Light'})"
                            : (isDark ? "Always Dark (Custom)" : "Always Light (Custom)"),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!settings.isThemeSystem)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => settings.resetThemeToSystem(),
                              child: const Text("Auto", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          Switch(
                            value: isDark,
                            activeTrackColor: primaryNavy,
                            onChanged: (val) => settings.toggleTheme(val),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                    // Biometric Login Switch
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBoxBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.fingerprint, color: primaryNavy),
                      ),
                      title: const Text("Biometric Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text("Use Fingerprint/FaceID", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Switch(
                        value: settings.biometricEnabled,
                        activeTrackColor: primaryNavy,
                        onChanged: (val) async {
                          final success = await settings.toggleBiometric(val);
                          if (context.mounted) {
                            if (success) {
                              UndoToastManager.showSuccessToast(
                                context: context,
                                title: "Biometric Updated",
                                subtitle: "Biometric authentication preference saved.",
                              );
                            } else {
                              UndoToastManager.showErrorToast(
                                context: context,
                                title: "Biometric Verification Failed",
                                subtitle: "Verification failed or was cancelled.",
                              );
                            }
                          }
                        },
                      ),
                      onTap: () async {
                        final success = await settings.toggleBiometric(!settings.biometricEnabled);
                        if (context.mounted) {
                          if (success) {
                            UndoToastManager.showSuccessToast(
                              context: context,
                              title: "Biometric Updated",
                              subtitle: "Biometric authentication preference saved.",
                            );
                          } else {
                            UndoToastManager.showErrorToast(
                              context: context,
                              title: "Biometric Verification Failed",
                              subtitle: "Verification failed or was cancelled.",
                            );
                          }
                        }
                      },
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                    // Swipe Actions Switch
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      onTap: () => settings.toggleSwipeActions(!settings.swipeActionsEnabled),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBoxBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.swipe_outlined, color: primaryNavy),
                      ),
                      title: const Text("Swipe Actions on Loans", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text("← Swipe left to delete\n→ Swipe right to pay EMI", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Switch(
                        value: settings.swipeActionsEnabled,
                        activeTrackColor: primaryNavy,
                        onChanged: (val) => settings.toggleSwipeActions(val),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── NOTIFICATIONS SECTION ──
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: primaryNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                "Notifications",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: sectionTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: GlassTheme.cardDecoration(context, radius: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Master Notification Switch
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      onTap: () => settings.toggleAllNotifications(!settings.notificationsEnabled),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBoxBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: primaryNavy),
                      ),
                      title: const Text("Allow Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text("Enable or pause all payment reminders", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: Switch(
                        value: settings.notificationsEnabled,
                        activeTrackColor: primaryNavy,
                        onChanged: (val) => settings.toggleAllNotifications(val),
                      ),
                    ),

                    if (settings.notificationsEnabled) ...[
                      Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                      // Due Today Alerts
                      ListTile(
                        onTap: () => settings.toggleNotifyDueToday(!settings.notifyDueToday),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconBoxBgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.alarm_on_rounded, color: Color(0xFFE65100)),
                        ),
                        title: const Text("Due Today Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text("Morning alert at 8:00 AM on payment day", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Switch(
                          value: settings.notifyDueToday,
                          activeTrackColor: primaryNavy,
                          onChanged: (val) => settings.toggleNotifyDueToday(val),
                        ),
                      ),
                      Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                      // Due Tomorrow (1 Day Before)
                      ListTile(
                        onTap: () => settings.toggleNotifyDueTomorrow(!settings.notifyDueTomorrow),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconBoxBgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.event_available_rounded, color: primaryNavy),
                        ),
                        title: const Text("1-Day Before Reminders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text("Evening reminder at 7:00 PM before due date", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Switch(
                          value: settings.notifyDueTomorrow,
                          activeTrackColor: primaryNavy,
                          onChanged: (val) => settings.toggleNotifyDueTomorrow(val),
                        ),
                      ),
                      Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                      // Advance Reminders (3 Days & 7 Days Prior)
                      ListTile(
                        onTap: () => settings.toggleNotifyAdvance(!settings.notifyAdvance),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconBoxBgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1976D2)),
                        ),
                        title: const Text("Advance Reminders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text("3-day and 7-day prior notices to prepare funds", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Switch(
                          value: settings.notifyAdvance,
                          activeTrackColor: primaryNavy,
                          onChanged: (val) => settings.toggleNotifyAdvance(val),
                        ),
                      ),
                      Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                      // Overdue Alerts
                      ListTile(
                        onTap: () => settings.toggleNotifyOverdue(!settings.notifyOverdue),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconBoxBgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
                        ),
                        title: const Text("Overdue & Missed Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text("Follow-up alert if an EMI date has passed", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Switch(
                          value: settings.notifyOverdue,
                          activeTrackColor: primaryNavy,
                          onChanged: (val) => settings.toggleNotifyOverdue(val),
                        ),
                      ),
                    ],

                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                    // Test Notification Button
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.send_rounded, color: Color(0xFF2E7D32)),
                      ),
                      title: const Text("Send Test Notification", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: const Text("Verify banner, sound & delivery instantly", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () async {
                        try {
                          await NotificationService().showTestNotification();
                          if (context.mounted) {
                            UndoToastManager.showSuccessToast(
                              context: context,
                              title: "Test Notification Sent 🔔",
                              subtitle: "Check your phone's notification tray.",
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final cleanErr = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '').trim();
                            UndoToastManager.showErrorToast(
                              context: context,
                              title: "Notification Error",
                              subtitle: cleanErr,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── 3. ACCOUNT SECTION ──
          Row(
            children: [
              const Icon(Icons.person_outline, color: primaryNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                "Account",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: sectionTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: GlassTheme.cardDecoration(context, radius: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Edit info
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBoxBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: primaryNavy),
                      ),
                      title: const Text("Edit Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _navigateToEditInfo,
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                    // Change Password
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBoxBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_outline, color: primaryNavy),
                      ),
                      title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () async {
                        if (user?.email != null) {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                          if (context.mounted) {
                            UndoToastManager.showSuccessToast(
                              context: context,
                              title: "Password Reset Sent 📧",
                              subtitle: "Check your email for reset instructions.",
                            );
                          }
                        }
                      },
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                    // Delete Account
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete_forever_outlined, color: Color(0xFFDC2626)),
                      ),
                      title: const Text(
                        "Delete Account",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      subtitle: const Text(
                        "7-day recovery or instant delete",
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFFDC2626)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const DeleteAccountScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                    // Logout
                    ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── 4. PRIVACY POLICY CARD ──
          Container(
            decoration: GlassTheme.cardDecoration(context, radius: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryNavy.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.policy_outlined, color: primaryNavy),
                  ),
                  title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text("How your data & security are protected", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(context, '/privacy_policy');
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              "© 2026 PayWise. All rights reserved.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
