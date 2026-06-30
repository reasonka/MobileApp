import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';


class LoginTokens {
  static const screenBg = Color(0xFF161823);
  static const horizontalPadding = 41.0;
  static const fieldHeight = 59.0;
  static const fieldRadius = 20.0;
  static const fieldHorizontalPadding = 28.5;
  static const logoWidth = 152.0;
  static const logoHeight = 104.0;
  static const logoRadius = 41.0;

  static const fieldGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.6,
    colors: [
      Color(0x80AF69F1),
      Color(0x80DA70D7),
      Color(0x80AE67BC),
      Color(0x80815EA0),
      Color(0x80555485),
      Color(0x803E5077),
      Color(0x80284B69),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
  );

  static const fieldShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
  );
}


class LoginScreenBackground extends StatelessWidget {
  const LoginScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LoginTokens.screenBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/login/login_bg.svg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }
}


class LoginCatLogo extends StatelessWidget {
  const LoginCatLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LoginTokens.logoRadius),
      child: Image.asset(
        'assets/images/login/cat_logo.png',
        width: LoginTokens.logoWidth,
        height: LoginTokens.logoHeight,
        fit: BoxFit.cover,
      ),
    );
  }
}


class LoginScreenTitle extends StatelessWidget {
  final String text;

  const LoginScreenTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 22 / 20,
      ),
    );
  }
}


class LoginGradientField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool allCaps;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final bool readOnly;

  const LoginGradientField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.allCaps = false,
    this.maxLength,
    this.inputFormatters,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: LoginTokens.fieldHeight,
      decoration: BoxDecoration(
        gradient: LoginTokens.fieldGradient,
        borderRadius: BorderRadius.circular(LoginTokens.fieldRadius),
        boxShadow: const [LoginTokens.fieldShadow],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters ??
            (allCaps
                ? [
                    TextInputFormatter.withFunction(
                      (old, next) =>
                          next.copyWith(text: next.text.toUpperCase()),
                    ),
                  ]
                : null),
        style: GoogleFonts.openSans(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: allCaps ? 3.0 : 0.0,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LoginTokens.fieldHorizontalPadding,
            vertical: 18,
          ),
          hintText: label,
          hintStyle: GoogleFonts.openSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}


class LoginGradientFieldShell extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isPlaceholder;

  const LoginGradientFieldShell({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: LoginTokens.fieldHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: LoginTokens.fieldHorizontalPadding,
        ),
        decoration: BoxDecoration(
          gradient: LoginTokens.fieldGradient,
          borderRadius: BorderRadius.circular(LoginTokens.fieldRadius),
          boxShadow: const [LoginTokens.fieldShadow],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.openSans(
                  color: isPlaceholder ? Colors.white : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class LoginErrorBanner extends StatelessWidget {
  final String message;

  const LoginErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
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
              message,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}


class LoginPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const LoginPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: LoginTokens.fieldHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2DBD), AppColors.pink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(LoginTokens.fieldRadius),
          boxShadow: const [LoginTokens.fieldShadow],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LoginTokens.fieldRadius),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
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
}


class LoginSocialAuthButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback? onTap;

  const LoginSocialAuthButton({
    super.key,
    required this.assetPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: 66,
          height: 66,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


class LoginSocialAuthRow extends StatelessWidget {
  const LoginSocialAuthRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Or continue with',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
            height: 22 / 17,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            LoginSocialAuthButton(
              assetPath: 'assets/images/login/apple_icon.png',
            ),
            SizedBox(width: 44),
            LoginSocialAuthButton(
              assetPath: 'assets/images/login/google_icon.png',
            ),
          ],
        ),
      ],
    );
  }
}


class LoginToggleLink extends StatelessWidget {
  final bool isSignIn;
  final VoidCallback onTap;

  const LoginToggleLink({
    super.key,
    required this.isSignIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: isSignIn ? 'New here? ' : 'Already have an account? ',
            ),
            TextSpan(
              text: isSignIn ? 'Create an account' : 'Sign In',
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
