import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../settings/settings_widgets.dart';
import 'login_widgets.dart';
import '../../services/firestore_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String email;
  final bool isEditing;

  const ProfileSetupScreen({
    super.key,
    required this.uid,
    required this.email,
    this.isEditing = false,
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
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    final data = doc.data();
    if (!mounted || data == null) return;

    DateTime? dob;
    final birthday = data['birthday'];
    final dateOfBirth = data['dateOfBirth'];
    if (birthday is Timestamp) {
      dob = birthday.toDate();
    } else if (dateOfBirth is Timestamp) {
      dob = dateOfBirth.toDate();
    }

    setState(() {
      _nameCtrl.text = (data['name'] as String?) ?? '';
      _birthday = dob;
      _selectedAvatar = data['avatarIndex'] as int? ?? 0;
    });
  }

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
      final payload = {
        'name': name,
        'email': widget.email,
        'birthday': Timestamp.fromDate(_birthday!),
        'dateOfBirth': Timestamp.fromDate(_birthday!),
        'avatarIndex': _selectedAvatar,
      };

      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .update(payload);
        if (mounted) Navigator.pop(context, true);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .set(payload);
      }
    } catch (_) {
      setState(() => _error = 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isEditing ? SettingsTokens.screenBg : LoginTokens.screenBg;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (!widget.isEditing) const LoginScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isEditing
                    ? SettingsTokens.horizontalPadding
                    : LoginTokens.horizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isEditing) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SvgPicture.asset(
                          SettingsTokens.iconAsset('back'),
                          width: 13,
                          height: 25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    const SizedBox(height: 44),
                    const Center(child: LoginCatLogo()),
                    const SizedBox(height: 36),
                  ],
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
                    label: widget.isEditing ? 'Save changes' : 'Continue',
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
                text: widget.isEditing ? 'Your ' : 'Tell us about\n',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: widget.isEditing ? 'account' : 'yourself',
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
          widget.isEditing
              ? 'Update your name, birthday, and cat'
              : 'Set up your Homie profile',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  static const _avatarAssets = [
    'assets/images/home/avatar_purple.png',
    'assets/images/home/avatar_blue.png',
    'assets/images/home/avatar_blue_wink.png',
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

    return GestureDetector(
      onTap: () => setState(() => _selectedAvatar = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.55),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ClipOval(
          child: Image.asset(
            _avatarAssets[index],
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
