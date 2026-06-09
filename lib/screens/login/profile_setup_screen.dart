import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String email;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  DateTime? _birthday;
  int _selectedAvatar = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ──────────────────────────────────────────────────────────────

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.pink,
            onPrimary: Colors.white,
            surface: AppColors.cardBg,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Save & continue ──────────────────────────────────────────────────────────
  // Saves the user profile doc to Firestore.
  // The AuthGate in main.dart listens to this doc; once it appears (without a
  // houseId) it will automatically route to FamilySetupScreen.

  Future<void> _continue() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (_birthday == null) {
      setState(() => _error = 'Please select your birthday.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({
        'name': name,
        'email': widget.email,
        'birthday': Timestamp.fromDate(_birthday!),
        'avatarIndex': _selectedAvatar,
        // houseId intentionally omitted — FamilySetupScreen sets it
      });
    } catch (_) {
      setState(() => _error = 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildNameField(),
                  const SizedBox(height: 14),
                  _buildBirthdayField(),
                  const SizedBox(height: 36),
                  _buildAvatarSection(),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorBanner(),
                  ],
                  const SizedBox(height: 36),
                  _buildContinueButton(),
                  const SizedBox(height: 32),
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
                  const Color(0xFFE040FB).withOpacity(0.32),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
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
                  const Color(0xFF1B5E20).withOpacity(0.38),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Tell us about\n',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'yourself',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your Homie profile',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Name field ───────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return _GradientPillField(
      controller: _nameCtrl,
      label: 'Your Name',
      keyboardType: TextInputType.name,
      obscureText: false,
    );
  }

  // ── Birthday field ───────────────────────────────────────────────────────────

  Widget _buildBirthdayField() {
    return GestureDetector(
      onTap: _pickBirthday,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D1370), Color(0xFF7B2DBD)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _birthday == null ? 'Birthday' : _formatDate(_birthday!),
                style: GoogleFonts.poppins(
                  color:
                      _birthday == null ? Colors.white70 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar selection ─────────────────────────────────────────────────────────

  // Three cat avatar options. Replace the Icon placeholders with your Canva
  // images once you have the asset files:
  //   Image.asset('assets/images/cat_0.png', fit: BoxFit.cover)
  //   Image.asset('assets/images/cat_1.png', fit: BoxFit.cover)
  //   Image.asset('assets/images/cat_2.png', fit: BoxFit.cover)
  // Don't forget to declare each file under flutter > assets in pubspec.yaml.

  static const _avatarGradients = [
    [Color(0xFF6A1B9A), Color(0xFFE040FB)], // purple cat
    [Color(0xFF1B5E20), Color(0xFF00C9A7)], // teal cat
    [Color(0xFF1A237E), Color(0xFF448AFF)], // blue cat
  ];

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your cat',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick the one that best represents you',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, _buildAvatarOption),
        ),
      ],
    );
  }

  Widget _buildAvatarOption(int index) {
    final selected = _selectedAvatar == index;
    final colors = _avatarGradients[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedAvatar = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.pink.withOpacity(0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        // TODO: Replace with Canva cat images:
        // child: ClipOval(child: Image.asset('assets/images/cat_$index.png', fit: BoxFit.cover))
        child: const Icon(Icons.pets_rounded, color: Colors.white, size: 42),
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
              _error!,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Continue button ──────────────────────────────────────────────────────────

  Widget _buildContinueButton() {
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
          onPressed: _loading ? null : _continue,
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
                  'Continue',
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

// ── Gradient pill text field (same style as login) ────────────────────────────

class _GradientPillField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  const _GradientPillField({
    required this.controller,
    required this.label,
    this.keyboardType, required this.obscureText,
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
        ),
      ),
    );
  }
}
