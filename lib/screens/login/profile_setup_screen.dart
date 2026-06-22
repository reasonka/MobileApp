import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'login_widgets.dart';

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
      });
    } catch (_) {
      setState(() => _error = 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginTokens.screenBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const LoginScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: LoginTokens.horizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 44),
                  const Center(child: LoginCatLogo()),
                  const SizedBox(height: 36),
                  _buildHeader(),
                  const SizedBox(height: 28),
                  LoginGradientField(
                    controller: _nameCtrl,
                    label: 'Your Name',
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 17),
                  LoginGradientFieldShell(
                    label: _birthday == null
                        ? 'Birthday'
                        : _formatDate(_birthday!),
                    isPlaceholder: _birthday == null,
                    onTap: _pickBirthday,
                    trailing: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildAvatarSection(),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    LoginErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 36),
                  LoginPrimaryButton(
                    label: 'Continue',
                    loading: _loading,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  static const _avatarGradients = [
    [Color(0xFF6A1B9A), Color(0xFFE040FB)],
    [Color(0xFF1B5E20), Color(0xFF00C9A7)],
    [Color(0xFF1A237E), Color(0xFF448AFF)],
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
        child: const Icon(Icons.pets_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}
