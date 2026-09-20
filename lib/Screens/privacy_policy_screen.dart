import 'package:flutter/material.dart';
import 'package:paywise/theme/glass_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
      ),
      body: GlassBackground(
        child: ScrolledNotificationWrapper(
          isScrolledNotifier: _isScrolled,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, totalTopPadding, 16, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context, isDark),
                const SizedBox(height: 20),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.block_flipped,
                  iconColor: Colors.orange,
                  title: "1. Zero Ads & No Data Monetization",
                  content:
                      "PayWise contains zero third-party advertising SDKs, tracker beacons, or data monetization libraries. Your financial profile, loan amounts, lender names, and repayment timelines are strictly private to you. We do not sell, rent, license, or share your data with advertisers or data brokers under any circumstance.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.mark_chat_unread_outlined,
                  iconColor: Colors.indigo,
                  title: "2. No SMS or Financial Surveillance",
                  content:
                      "Unlike conventional finance apps that demand access to your SMS inbox, contacts, or bank account credentials, PayWise never requests or scans your private messages. The application strictly processes only the loans, interest rates, and payments that you deliberately input.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.fingerprint_rounded,
                  iconColor: Colors.teal,
                  title: "3. Hardware-Backed Biometrics",
                  content:
                      "When Biometric Lock is enabled, authentication is handled natively by your device's hardware-backed Secure Enclave (Apple Keychain on iOS / Android Keystore). Biometric fingerprints and Face ID data never leave your device. The app operates on a fail-closed architecture: if biometric verification is cancelled or errors occur, data access remains completely locked.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.visibility_off_outlined,
                  iconColor: Colors.purple,
                  title: "4. Multitasking Privacy Shield",
                  content:
                      "To safeguard your privacy against shoulder-surfing and OS-level screenshot caching, PayWise automatically activates an opaque Security Privacy Curtain the moment the app is minimized or sent to the background app switcher. No financial numbers are ever exposed in system previews.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.cloud_done_outlined,
                  iconColor: Colors.blue,
                  title: "5. Strict Cloud Isolation & Encryption",
                  content:
                      "All cloud synchronizations are performed over encrypted channels using TLS 1.3 in transit and AES-256 encryption at rest within Cloud Firestore. Each user's data is isolated under a unique, sandboxed Firestore path (/users/{uid}/loans/). Users cannot query, view, or alter records belonging to any other user.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.offline_pin_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: "6. Offline Persistence & Local Cache",
                  content:
                      "PayWise utilizes local encrypted on-device persistence. You can track loans, review amortizations, and run repayment simulations completely offline. Any modifications made while offline are stored securely and synchronized as soon as network connectivity is re-established.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: "7. Right to Erasure & Account Deletion",
                  content:
                      "You maintain total ownership of your financial records. You can delete your account at any time through Settings > Delete Account. We offer a 7-Day Safety Recovery period with 1-tap restore upon login, or an Immediate Permanent Deletion option that irreversibly purges your profile, all loan documents, all payment history, and authentication credentials permanently.",
                ),
                const SizedBox(height: 14),

                _buildPolicyCard(
                  context,
                  isDark: isDark,
                  icon: Icons.contact_support_outlined,
                  iconColor: Colors.cyan,
                  title: "8. Inquiries & Contact",
                  content:
                      "If you have questions, feedback, or concerns regarding your privacy or data protection practices in PayWise, please reach out to our privacy team at support@paywise.app.",
                ),
                const SizedBox(height: 24),

                Center(
                  child: Text(
                    "PayWise Version 1.0.0\n© 2026 PayWise. All rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      height: 1.5,
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

  Widget _buildHeroHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: GlassTheme.cardDecoration(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.indigo, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PayWise Privacy Policy",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Your financial privacy is our top priority",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "PayWise is architected with a strict privacy-first philosophy. We believe your personal liabilities, loan terms, and repayment strategies belong solely to you.",
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPill(context, "Zero Ads", Colors.orange),
              _buildPill(context, "No SMS Scraping", Colors.indigo),
              _buildPill(context, "Hardware Biometrics", Colors.teal),
              _buildPill(context, "Encrypted Storage", const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: GlassTheme.pillDecoration(context, color: color, radius: 8),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: GlassTheme.cardDecoration(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
