import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/theme/glass_theme.dart';

class EditInfoScreen extends StatefulWidget {
  const EditInfoScreen({super.key});

  @override
  State<EditInfoScreen> createState() => _EditInfoScreenState();
}

class _EditInfoScreenState extends State<EditInfoScreen> {
  final AuthService _authService = AuthService();
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  DateTime? _birthdate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _isScrolled.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final displayName = user.displayName ?? '';
        final email = user.email ?? '';

        // Initialize from display name
        final parts = displayName.trim().split(' ');
        if (parts.length > 1) {
          _firstNameController.text = parts.first;
          _lastNameController.text = parts.sublist(1).join(' ');
        } else {
          _firstNameController.text = displayName;
          _lastNameController.text = '';
        }

        _emailController.text = email;
        _usernameController.text = displayName.isNotEmpty
            ? displayName.toLowerCase().replaceAll(' ', '')
            : (email.split('@').first);

        try {
          final profile = await _authService.getUserProfile(user.uid);
          if (profile.isNotEmpty) {
            if (profile['firstName'] != null && (profile['firstName'] as String).isNotEmpty) {
              _firstNameController.text = profile['firstName'];
            }
            if (profile['lastName'] != null && (profile['lastName'] as String).isNotEmpty) {
              _lastNameController.text = profile['lastName'];
            }
            if (profile['username'] != null && (profile['username'] as String).isNotEmpty) {
              _usernameController.text = profile['username'];
            }
            if (profile['email'] != null && (profile['email'] as String).isNotEmpty) {
              _emailController.text = profile['email'];
            }
            if (profile['birthdate'] != null) {
              _birthdate = DateTime.tryParse(profile['birthdate'] as String);
            }
          }
        } catch (e) {
          debugPrint("Error loading profile: $e");
        }
      }
    } catch (e) {
      debugPrint("FirebaseAuth not available or error: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickBirthdate(BuildContext context) async {
    final initialDate = _birthdate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2A5298),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E2235),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF1E3C72),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  Future<void> _saveInfo() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim().replaceAll('@', '');

    if (firstName.isEmpty) {
      UndoToastManager.showErrorToast(
        context: context,
        title: "Missing Name",
        subtitle: "Please enter your first name.",
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      UndoToastManager.showErrorToast(
        context: context,
        title: "Invalid Email",
        subtitle: "Please enter a valid email address.",
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        birthdate: _birthdate,
      );

      if (mounted) {
        UndoToastManager.showSuccessToast(
          context: context,
          title: "Profile Updated ✨",
          subtitle: "Your personal info has been successfully saved.",
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '').trim();
        UndoToastManager.showErrorToast(
          context: context,
          title: "Update Failed",
          subtitle: cleanMsg,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showAddAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.45)
          : const Color(0xFF0F172A).withValues(alpha: 0.22),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              decoration: GlassTheme.bottomSheetDecoration(context, radius: 28),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3C72).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF1E3C72), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Add Another Account",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "You will be logged out of your current account to sign in with a different PayWise account or register a new one.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _authService.signOut();
                    if (mounted) {
                      Provider.of<LoanProvider>(context, listen: false).clearUserData();
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text(
                    "Sign In to Another Account",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
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
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final totalTopPadding = topPadding + kToolbarHeight + 12;

    const primaryNavy = Color(0xFF1E3C72);
    const primaryNavyLight = Color(0xFF2A5298);
    final iconBoxBgColor = isDark ? primaryNavy.withValues(alpha: 0.25) : const Color(0xFFEBF1F9);
    final sectionTextColor = isDark ? const Color(0xFF90B3E8) : primaryNavy;
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final photoURL = user?.photoURL;
    final String initialChar = _firstNameController.text.isNotEmpty
        ? _firstNameController.text[0].toUpperCase()
        : (user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : "U");

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Edit Info",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: GlassTheme.frostedAppBarFlexibleSpace(
          context,
          isScrolledNotifier: _isScrolled,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _saveInfo,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      "Save",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2979FF),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GlassBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ScrolledNotificationWrapper(
                isScrolledNotifier: _isScrolled,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(8, totalTopPadding, 8, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. AVATAR DISPLAY ──
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
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
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: (photoURL != null && photoURL.isNotEmpty)
                                        ? Image.network(
                                            photoURL,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, trace) => Center(
                                              child: Text(
                                                initialChar,
                                                style: const TextStyle(
                                                  fontSize: 38,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              initialChar,
                                              style: const TextStyle(
                                                fontSize: 38,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2979FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF0C0E17) : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${_firstNameController.text} ${_lastNameController.text}".trim().isNotEmpty
                                  ? "${_firstNameController.text} ${_lastNameController.text}".trim()
                                  : (user?.displayName ?? "User"),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── 2. "YOUR NAME" SECTION ──
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: primaryNavy, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Your Name",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: sectionTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: GlassTheme.cardDecoration(context, radius: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              // First Name
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextFormField(
                                  controller: _firstNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: "First Name",
                                    hintText: "Enter your first name",
                                    prefixIcon: Icon(Icons.person_outline_rounded, color: primaryNavy),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                endIndent: 16,
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                              ),
                              // Last Name
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextFormField(
                                  controller: _lastNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: "Last Name",
                                    hintText: "Enter your last name",
                                    prefixIcon: Icon(Icons.person_outline_rounded, color: primaryNavy),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 3. "YOUR INFO" SECTION ──
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: primaryNavy, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Your Info",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: sectionTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: GlassTheme.cardDecoration(context, radius: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              // Email
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: "Email",
                                    hintText: "your.email@example.com",
                                    prefixIcon: Icon(Icons.mail_outline_rounded, color: primaryNavy),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                endIndent: 16,
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                              ),
                              // Username
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: "Username",
                                    hintText: "username",
                                    prefixIcon: Icon(Icons.alternate_email_rounded, color: primaryNavy),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                endIndent: 16,
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                              ),
                              // Birthdate
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _pickBirthdate(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cake_outlined, color: primaryNavy),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Birthdate",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _birthdate != null
                                                    ? DateFormat('dd MMMM yyyy').format(_birthdate!)
                                                    : "Set your birthdate",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: _birthdate != null
                                                      ? (isDark ? Colors.white : Colors.black87)
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          color: isDark ? const Color(0xFF90B3E8) : primaryNavy,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 4. IN ONE CARD: "Add account" & "Logout" ──
                      Row(
                        children: [
                          const Icon(Icons.manage_accounts_outlined, color: primaryNavy, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Account",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: sectionTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: GlassTheme.cardDecoration(context, radius: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                // Add Account
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: iconBoxBgColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.person_add_alt_1_outlined, color: primaryNavy),
                                  ),
                                  title: const Text(
                                    "Add Account",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  subtitle: const Text(
                                    "Sign in with another account",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  onTap: _showAddAccountDialog,
                                ),
                                Divider(
                                  height: 1,
                                  indent: 64,
                                  endIndent: 16,
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                ),
                                // Logout
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.logout_rounded, color: Colors.red),
                                  ),
                                  title: const Text(
                                    "Log Out",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.red,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Sign out of PayWise",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  onTap: _confirmLogout,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
