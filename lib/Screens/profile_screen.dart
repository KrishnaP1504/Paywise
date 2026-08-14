import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/Screens/delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Username", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Username / Full Name",
            prefixIcon: Icon(Icons.person, color: Color(0xFF1E3C72)),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3C72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                await _authService.updateDisplayName(newName);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.themeMode == ThemeMode.dark;

    final String displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : (user?.email?.split('@').first ?? "User");

    // Exact Deep Navy Blue Palette matching Dashboard Total Outstanding Card
    const primaryNavy = Color(0xFF1E3C72);
    const primaryNavyLight = Color(0xFF2A5298);
    final cardBgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final iconBoxBgColor = isDark ? primaryNavy.withValues(alpha: 0.25) : const Color(0xFFEBF1F9);
    final sectionTextColor = isDark ? const Color(0xFF90B3E8) : primaryNavy;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile & Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          // ── 1. TOP PROFILE CARD ──
          Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                // Curved Gradient Top Header matching Dashboard Card (#1E3C72 → #2A5298)
                Container(
                  height: 95,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryNavy, primaryNavyLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
                // Overlapping Avatar & User Details
                Transform.translate(
                  offset: const Offset(0, -45),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: cardBgColor,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: primaryNavy,
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Edit Name Pencil Button
                          GestureDetector(
                            onTap: () => _showEditNameDialog(context, displayName),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: Column(
              children: [
                // Dark Mode Switch
                ListTile(
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
                  subtitle: const Text("Easy on the eyes at night", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Switch(
                    value: isDark,
                    activeTrackColor: primaryNavy,
                    onChanged: (val) => settings.toggleTheme(val),
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
                    onChanged: (val) {
                      settings.toggleBiometric(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Biometric preference saved.')),
                      );
                    },
                  ),
                ),
                Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                // Swipe Actions Switch
                ListTile(
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
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: Column(
              children: [
                // Edit Username
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBoxBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_outline, color: primaryNavy),
                  ),
                  title: const Text("Edit Username", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _showEditNameDialog(context, displayName),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password reset email sent.")),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),

          const SizedBox(height: 20),

          // ── 4. HELP CARD ──
          Container(
            decoration: BoxDecoration(
              color: isDark ? primaryNavy.withValues(alpha: 0.15) : const Color(0xFFEBF1F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? primaryNavy.withValues(alpha: 0.3) : primaryNavy.withValues(alpha: 0.15),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryNavy.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_outlined, color: primaryNavy),
                ),
                title: const Text("We're here to help", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text("Visit Help Center for support", style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Help Center feature coming soon!")),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Version 1.2.0",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
