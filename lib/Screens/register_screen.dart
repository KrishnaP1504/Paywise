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

          // ── MAIN SCROLLABLE CONTENT ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── 1. HEADER WITH BACK BUTTON & TITLE ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            width: 44,
                            height: 44,
                            decoration: GlassTheme.cardDecoration(context, radius: 22, customBg: cardFill),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: textDark,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title and Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Join PayWise and start your smart financial journey.",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: textSub,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── 2. AVATAR ILLUSTRATION WITH ACCENT SPARKLES ──
                    SizedBox(
                      width: 200,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Decorative Sparkle Accents
                          const Positioned(
                            top: 15,
                            left: 20,
                            child: _DotDecoration(color: Color(0xFF60A5FA), size: 10),
                          ),
                          const Positioned(
                            top: 10,
                            left: 45,
                            child: _DotDecoration(color: Color(0xFF34D399), size: 7),
                          ),
                          const Positioned(
                            bottom: 35,
                            left: 35,
                            child: Icon(Icons.star_rounded, color: Color(0xFFA78BFA), size: 14),
                          ),
                          const Positioned(
                            top: 30,
                            right: 40,
                            child: Icon(Icons.star_outline_rounded, color: Color(0xFFA78BFA), size: 14),
                          ),
                          const Positioned(
                            bottom: 25,
                            right: 35,
                            child: Icon(Icons.star_rounded, color: Color(0xFF34D399), size: 14),
                          ),
                          const Positioned(
                            bottom: 45,
                            right: 20,
                            child: _DotDecoration(color: Color(0xFFA78BFA), size: 8),
                          ),

                          // Main 3D Person Avatar Circle
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF222638) : const Color(0xFFF2F4FE),
                              border: Border.all(color: borderCol, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3849C4).withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 54,
                                color: Color(0xFF3B4CCA),
                              ),
                            ),
                          ),

                          // Plus Badge on Bottom Right of Avatar
                          Positioned(
                            bottom: 12,
                            right: 58,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardFill,
                                border: Border.all(color: const Color(0xFF3B4CCA), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Color(0xFF3B4CCA),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── 3. JOIN PAYWISE BRANDING & SHIELD DIVIDER ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Join ",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          "PayWise",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3B4CCA),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Shield Divider Line
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: borderCol,
                            margin: const EdgeInsets.only(left: 30),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.shield_rounded,
                            color: Color(0xFF3B4CCA),
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: borderCol,
                            margin: const EdgeInsets.only(right: 30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Create your account to get started",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: textSub,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 4. FROSTED REGISTRATION FORM CARD ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: GlassTheme.cardDecoration(context, radius: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FULL NAME
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Full Name",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
                            decoration: InputDecoration(
                              hintText: "Enter your full name",
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                              fillColor: cardFill,
                              filled: true,
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderCol, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.red, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.red, width: 1.8),
                              ),
                            ),
                            validator: (val) => val != null && val.trim().isNotEmpty ? null : "Enter your name",
                          ),

                          const SizedBox(height: 12),

                          // GMAIL ADDRESS
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Gmail Address",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
                            decoration: InputDecoration(
                              hintText: "yourname@gmail.com",
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                              fillColor: cardFill,
                              filled: true,
                              prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderCol, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.red, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
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

                          const SizedBox(height: 12),

                          // PASSWORD
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
                            decoration: InputDecoration(
                              hintText: "Min 8 chars, 1 uppercase, 1 number",
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                              fillColor: cardFill,
                              filled: true,
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderCol, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.red, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
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

                          const SizedBox(height: 12),

                          // CONFIRM PASSWORD
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Confirm Password",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _confirmPassController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, letterSpacing: 2),
                              fillColor: cardFill,
                              filled: true,
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF3B4CCA), size: 18),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderCol, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 1.8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.red, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.red, width: 1.8),
                              ),
                            ),
                            validator: (val) => val == _passController.text ? null : "Passwords do not match",
                          ),

                          const SizedBox(height: 20),

                          // ── REGISTER BUTTON ──
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [Color(0xFF6366F1), Color(0xFF4F46E5)]
                                    : const [Color(0xFF1E3C72), Color(0xFF2A5298)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.50),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF1E3C72))
                                      .withValues(alpha: 0.38),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "REGISTER",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 6. ALREADY HAVE AN ACCOUNT LINK ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: textSub, fontSize: 13),
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
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF3B4CCA),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
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

// ── DECORATIVE DOT BADGE ──
class _DotDecoration extends StatelessWidget {
  final Color color;
  final double size;

  const _DotDecoration({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
