import 'package:flutter/material.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:paywise/Screens/email_verification_screen.dart';
import 'package:paywise/theme/glass_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(
        _emailController.text.trim(),
        _passController.text.trim(),
        _nameController.text.trim(),
      );

      if (user != null && mounted) {
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint("Verification email send notice: $e");
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(user: user),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('email-already-in-use')) {
          msg = "Email is already registered.";
        } else if (msg.contains('weak-password')) {
          msg = "Password is too weak.";
        } else {
          msg = msg.replaceAll('Exception: ', '').replaceAll('Error: ', '').trim();
        }
        UndoToastManager.showErrorToast(
          context: context,
          title: "Registration Failed",
          subtitle: msg,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardFill = isDark
        ? const Color(0xFF1E2138).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.70);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.85);
    final textDark = isDark ? Colors.white : const Color(0xFF161C40);
    final textSub = isDark ? const Color(0xFFA0A7C2) : const Color(0xFF6B7280);

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, '/login');
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: GlassBackground(
          child: Stack(
            children: [
          // ── TOP DECORATIVE WAVE CURVE ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SizedBox(
                height: 180,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _TopWavePainter(
                      color: isDark
                          ? const Color(0xFF3B4CCA).withValues(alpha: 0.12)
                          : const Color(0xFFEEF1FF),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── MAIN CONTENT (Scroll-Free Compact Viewport) ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 1. COMPACT HEADER WITH BACK BUTTON & TITLE ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Circular Elevated Back Button
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: GlassTheme.cardDecoration(context, radius: 20, customBg: cardFill),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: textDark,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Join PayWise to manage your finances smarter.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: textSub,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── 2. STREAMLINED FROSTED REGISTRATION FORM CARD ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: GlassTheme.cardDecoration(context, radius: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // FULL NAME
                            Text(
                              "Full Name",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textDark),
                              decoration: InputDecoration(
                                hintText: "Enter your full name",
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                                fillColor: cardFill,
                                filled: true,
                                isDense: true,
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
                                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderCol, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.8),
                                ),
                              ),
                              validator: (val) => val != null && val.trim().isNotEmpty ? null : "Enter your name",
                            ),

                            const SizedBox(height: 8),

                            // GMAIL ADDRESS
                            Text(
                              "Gmail Address",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textDark),
                              decoration: InputDecoration(
                                hintText: "yourname@gmail.com",
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                                fillColor: cardFill,
                                filled: true,
                                isDense: true,
                                prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
                                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderCol, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return "Gmail address is required";
                                final email = val.trim().toLowerCase();
                                if (!email.endsWith('@gmail.com') || email.length <= 10) {
                                  return "Only @gmail.com emails are allowed";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            // PASSWORD
                            Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            TextFormField(
                              controller: _passController,
                              obscureText: _obscurePassword,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textDark),
                              decoration: InputDecoration(
                                hintText: "Min 8 chars, 1 uppercase, 1 number",
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                                fillColor: cardFill,
                                filled: true,
                                isDense: true,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
                                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                suffixIcon: IconButton(
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF3B4CCA),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderCol, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 8) return "Min 8 characters required";
                                if (!RegExp(r'[A-Z]').hasMatch(val)) return "Include at least 1 uppercase letter";
                                if (!RegExp(r'[0-9]').hasMatch(val)) return "Include at least 1 number";
                                if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) return "Include at least 1 special character";
                                return null;
                              },
                            ),

                            const SizedBox(height: 8),

                            // CONFIRM PASSWORD
                            Text(
                              "Confirm Password",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            TextFormField(
                              controller: _confirmPassController,
                              obscureText: _obscureConfirmPassword,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: textDark),
                              decoration: InputDecoration(
                                hintText: "••••••••",
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15, letterSpacing: 2),
                                fillColor: cardFill,
                                filled: true,
                                isDense: true,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
                                prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                suffixIcon: IconButton(
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF3B4CCA),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderCol, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.8),
                                ),
                              ),
                              validator: (val) => val == _passController.text ? null : "Passwords do not match",
                            ),

                            const SizedBox(height: 14),

                            // ── REGISTER BUTTON ──
                            GlassButton(
                              width: double.infinity,
                              height: 46,
                              radius: 14,
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _register,
                              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              child: const Text(
                                "REGISTER",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── LEGAL TERMS & PRIVACY FOOTNOTE ──
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "By registering, you agree to our ",
                                    style: TextStyle(color: textSub, fontSize: 11),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/terms_conditions'),
                                    child: const Text(
                                      "Terms",
                                      style: TextStyle(
                                        color: Color(0xFF3B4CCA),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    " & ",
                                    style: TextStyle(color: textSub, fontSize: 11),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
                                    child: const Text(
                                      "Privacy Policy",
                                      style: TextStyle(
                                        color: Color(0xFF3B4CCA),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 3. ALREADY HAVE AN ACCOUNT LINK ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(color: textSub, fontSize: 12.5),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Row(
                              children: [
                                Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Color(0xFF3B4CCA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF3B4CCA),
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
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
    );
  }
}

// ── CUSTOM PAINTER FOR TOP BACKGROUND WAVE ──
class _TopWavePainter extends CustomPainter {
  final Color color;

  _TopWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.15,
      size.width,
      size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TopWavePainter oldDelegate) => oldDelegate.color != color;
}
