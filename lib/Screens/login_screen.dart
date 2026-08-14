import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.login(_emailController.text.trim(), _passController.text.trim());
    } catch (e) {
      if (mounted) {
        String msg = "Login Failed";
        final errStr = e.toString();
        if (errStr.contains('user-not-found') || errStr.contains('invalid-credential')) {
          msg = "User not found or incorrect credentials";
        } else if (errStr.contains('wrong-password')) {
          msg = "Incorrect password";
        } else if (errStr.contains('invalid-email')) {
          msg = "Invalid email address";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final resetFormKey = GlobalKey<FormState>();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.indigo.withValues(alpha: 0.25) : const Color(0xFFEEF0FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, size: 36, color: Color(0xFF3B4CCA)),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Reset Password",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your registered @gmail.com address below to receive a secure reset link.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Form(
              key: resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Gmail Address",
                      hintText: "yourname@gmail.com",
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF3B4CCA)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Email is required";
                      final email = val.trim().toLowerCase();
                      if (!email.endsWith('@gmail.com') || email.length <= 10) {
                        return "Only @gmail.com emails are allowed";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF3B4CCA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: isResetting
                          ? null
                          : () async {
                              if (!resetFormKey.currentState!.validate()) return;

                              setDialogState(() => isResetting = true);
                              final email = resetEmailController.text.trim().toLowerCase();

                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                if (dialogCtx.mounted) {
                                  Navigator.pop(dialogCtx);
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    SnackBar(
                                      content: Text("Reset link sent to $email! Check your inbox."),
                                      backgroundColor: const Color(0xFF2E7D32),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setDialogState(() => isResetting = false);
                                String errMsg = "Failed to send reset link.";
                                if (e.toString().contains('user-not-found')) {
                                  errMsg = "No registered user found with this Gmail.";
                                } else if (e.toString().contains('invalid-email')) {
                                  errMsg = "Invalid Gmail address.";
                                }
                                if (dialogCtx.mounted) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      child: isResetting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Send Link", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome, ${user.displayName ?? 'User'}!"),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google Sign-In failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF10121D) : const Color(0xFFF9FAFE);
    final cardFill = isDark ? const Color(0xFF1A1D2D) : const Color(0xFFF8F9FF);
    final borderCol = isDark ? const Color(0xFF2D324A) : const Color(0xFFD4D9F5);
    final textDark = isDark ? Colors.white : const Color(0xFF161C40);
    final textSub = isDark ? const Color(0xFFA0A7C2) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── 1. TOP-LEFT DOT MATRIX GRID DECORATION ──
          Positioned(
            top: 40,
            left: 20,
            child: IgnorePointer(
              child: _DotGridDecoration(
                dotColor: isDark
                    ? const Color(0xFF2D324A).withValues(alpha: 0.6)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),

          // ── 2. TOP-RIGHT CONCENTRIC RIPPLE CIRCLES ──
          Positioned(
            top: -40,
            right: -50,
            child: IgnorePointer(
              child: _RippleCirclesDecoration(
                circleColor: isDark
                    ? const Color(0xFF3B4CCA).withValues(alpha: 0.08)
                    : const Color(0xFF3B4CCA).withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── 3. BOTTOM DECORATIVE WAVES ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: _BottomWavesPainter(
                    color: isDark
                        ? const Color(0xFF3B4CCA).withValues(alpha: 0.12)
                        : const Color(0xFF3B4CCA).withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),

          // ── MAIN CONTENT (Zero Scroll Fit) ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 1. PAYWISE LOGO BADGE (Direct 165x165 Image) ──
                      SizedBox(
                        width: 180,
                        height: 165,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Floating Bubble Accents
                            const Positioned(
                              top: 20,
                              left: 10,
                              child: _BubbleDecoration(size: 10),
                            ),
                            const Positioned(
                              top: 24,
                              right: 15,
                              child: _BubbleDecoration(size: 8),
                            ),
                            const Positioned(
                              bottom: 20,
                              left: 20,
                              child: _BubbleDecoration(size: 8),
                            ),
                            // Main PayWise Logo Image Emblem (165x165)
                            Container(
                              width: 165,
                              height: 165,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/images/paywise_logo.png',
                                width: 165,
                                height: 165,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 130,
                                  height: 130,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B4CCA),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 60),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ── 2. BRAND TITLE (PayWise) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pay",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const Text(
                            "Wise",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3B4CCA),
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── SHIELD DIVIDER LINE ──
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: borderCol,
                              margin: const EdgeInsets.only(left: 35),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B4CCA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: borderCol,
                              margin: const EdgeInsets.only(right: 35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── TAGLINE ──
                      Text(
                        "Smart Loans, Smarter You",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSub,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── 3. EMAIL ADDRESS FIELD ──
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Email Address",
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
                          if (val == null || val.trim().isEmpty) return "Email is required";
                          final email = val.trim().toLowerCase();
                          if (!email.endsWith('@gmail.com') || email.length <= 10) {
                            return "Only @gmail.com emails are allowed";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // ── 4. PASSWORD FIELD ──
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
                          hintText: "••••••••",
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, letterSpacing: 2),
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
                        validator: (val) => val != null && val.isNotEmpty ? null : "Password is required",
                      ),

                      const SizedBox(height: 2),

                      // ── FORGOT PASSWORD ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Color(0xFF3B4CCA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── 5. LOGIN BUTTON ──
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3849C4), Color(0xFF2C399B)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3849C4).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text(
                                      "LOGIN",
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

                      const SizedBox(height: 14),

                      // ── 6. OR DIVIDER ──
                      Row(
                        children: [
                          Expanded(child: Divider(color: borderCol)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "or",
                              style: TextStyle(color: textSub, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(child: Divider(color: borderCol)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── 7. GOOGLE SIGN-IN BUTTON ──
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: cardFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderCol, width: 1.2),
                        ),
                        child: OutlinedButton(
                          onPressed: _googleLogin,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildGoogleGLogo(),
                              const SizedBox(width: 10),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── 8. REGISTER LINK ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(color: textSub, fontSize: 13),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: Row(
                              children: const [
                                Text(
                                  "Register",
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleGLogo() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF4285F4), // Blue
            Color(0xFFEA4335), // Red
            Color(0xFFFBBC05), // Yellow
            Color(0xFF34A853), // Green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: const Text(
          "G",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── CUSTOM PAINTER FOR ELEGANT BOTTOM WAVES ──
class _BottomWavesPainter extends CustomPainter {
  final Color color;

  _BottomWavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yOffset = i * 14.0;

      path.moveTo(0, size.height * 0.4 + yOffset);
      path.cubicTo(
        size.width * 0.25,
        size.height * 0.85 + yOffset,
        size.width * 0.45,
        size.height * 0.1 + yOffset,
        size.width * 0.65,
        size.height * 0.6 + yOffset,
      );
      path.cubicTo(
        size.width * 0.8,
        size.height * 0.95 + yOffset,
        size.width * 0.9,
        size.height * 0.35 + yOffset,
        size.width,
        size.height * 0.5 + yOffset,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BottomWavesPainter oldDelegate) => oldDelegate.color != color;
}

// ── DOT GRID DECORATION (TOP LEFT) ──
class _DotGridDecoration extends StatelessWidget {
  final Color dotColor;

  const _DotGridDecoration({required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (c) => Container(
                margin: const EdgeInsets.only(right: 7),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CONCENTRIC RIPPLE CIRCLES DECORATION (TOP RIGHT) ──
class _RippleCirclesDecoration extends StatelessWidget {
  final Color circleColor;

  const _RippleCirclesDecoration({required this.circleColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(
          4,
          (i) => Container(
            width: (i + 1) * 42.0,
            height: (i + 1) * 42.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: circleColor, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── FLOATING BUBBLE DECORATION ──
class _BubbleDecoration extends StatelessWidget {
  final double size;

  const _BubbleDecoration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3B4CCA).withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}
