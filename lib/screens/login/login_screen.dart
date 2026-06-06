import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSignIn = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _fieldsHaveContent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onFieldChanged);
    _passwordCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final filled =
        _emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty;
    if (filled != _fieldsHaveContent) setState(() => _fieldsHaveContent = filled);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignIn) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // AuthGate in main.dart handles routing after sign-in
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // AuthGate detects no Firestore user doc → routes to ProfileSetupScreen
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildGlowBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  _buildCatLogo(),
                  const SizedBox(height: 28),
                  _buildTitle(),
                  const SizedBox(height: 36),
                  _buildEmailField(),
                  const SizedBox(height: 14),
                  _buildPasswordField(),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildAnimatedActionArea(),
                  const SizedBox(height: 48),
                  _buildToggleLink(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ───────────────────────────────────────────────────────────────

  Widget _buildGlowBackground() {
    return Stack(
      children: [
        // Pink/magenta glow at top (matches Canva design)
        Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 0.9,
                colors: [
                  const Color(0xFFE040FB).withOpacity(0.38),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Green glow at bottom (matches Canva design)
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 0.9,
                colors: [
                  const Color(0xFF1B5E20).withOpacity(0.42),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Cat logo ─────────────────────────────────────────────────────────────────

  Widget _buildCatLogo() {
    // TODO: Replace the placeholder below with your Canva cat image:
    //   Image.asset('assets/images/cat_logo.png', width: 120, height: 120)
    // Make sure to declare the asset in pubspec.yaml first.
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2DBD), Color(0xFFE040FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.45),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.pets_rounded, color: Colors.white, size: 54),
    );
  }

  // ── Title ────────────────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Text(
      _isSignIn ? 'SIGN IN' : 'CREATE AN ACCOUNT',
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 2.5,
      ),
    );
  }

  // ── Fields ───────────────────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return _GradientPillField(
      controller: _emailCtrl,
      label: 'Email',
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return _GradientPillField(
      controller: _passwordCtrl,
      label: 'Password',
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white54,
          size: 20,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    );
  }

  // ── Error banner ─────────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated action area ──────────────────────────────────────────────────────
  // When both fields are empty → show "Or continue with" + Apple/Google (decorative).
  // When both fields have content → those fade out, "Create Account"/"Sign In" fades in.

  Widget _buildAnimatedActionArea() {
    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Social buttons (decorative — no action)
          AnimatedOpacity(
            opacity: _fieldsHaveContent ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: _fieldsHaveContent,
              child: _buildSocialArea(),
            ),
          ),
          // Action button
          AnimatedOpacity(
            opacity: _fieldsHaveContent ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_fieldsHaveContent,
              child: _buildActionButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Or continue with',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialCircle(child: const Icon(Icons.apple, color: Colors.black, size: 28)),
            const SizedBox(width: 16),
            _SocialCircle(
              child: Text(
                'G',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4285F4),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2DBD), AppColors.pink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withOpacity(0.42),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isSignIn ? 'Sign In' : 'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Toggle sign-in / sign-up ──────────────────────────────────────────────────

  Widget _buildToggleLink() {
    return GestureDetector(
      onTap: () => setState(() {
        _isSignIn = !_isSignIn;
        _errorMessage = null;
        _emailCtrl.clear();
        _passwordCtrl.clear();
      }),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: _isSignIn ? "New here? " : "Already have an account? ",
            ),
            TextSpan(
              text: _isSignIn ? 'Create an account' : 'Sign In',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.pink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

/// Purple-gradient pill-shaped text field matching the Canva design.
class _GradientPillField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _GradientPillField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1370), Color(0xFF7B2DBD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

/// Round white circle for decorative social sign-in buttons.
class _SocialCircle extends StatelessWidget {
  final Widget child;
  const _SocialCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: Center(child: child),
    );
  }
}
