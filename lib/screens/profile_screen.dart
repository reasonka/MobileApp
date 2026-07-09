import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../services/theme_service.dart';
import '../../theme.dart';
import 'home/home_widgets.dart';
import 'login/profile_setup_screen.dart';
import 'settings/settings_detail_screens.dart';
import 'settings/settings_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String houseId;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.houseId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _fs = FirestoreService();

  
  String _name = '';
  String _houseName = '';
  String _inviteCode = '';
  int _avatarIndex = 0;
  DateTime? _dateOfBirth;
  String? _bio;
  bool _loading = true;
  bool _isOwner = false;

  Color get _bg => HomiePalette.current.screenBg;
  Color get _card => HomiePalette.current.cardBg;
  static const _pink = Color(0xFFE040FB);
  Color get _textSec => AppColors.textSecondary;
  Color get _divider => HomiePalette.current.divider;

  String get _themeLabel => switch (ThemeService.instance.preference) {
        HomieThemePreference.dark => 'Dark',
        HomieThemePreference.light => 'Light',
        HomieThemePreference.system => 'System',
      };

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
    _load();
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final userDoc = await _db.collection('users').doc(widget.userId).get();
    final houseDoc = await _db.collection('houses').doc(widget.houseId).get();
    if (!mounted) return;
    final d = userDoc.data() ?? {};
    final house = houseDoc.data() ?? {};
    DateTime? dob;
    final birthday = d['birthday'];
    final dateOfBirth = d['dateOfBirth'];
    if (birthday is Timestamp) {
      dob = birthday.toDate();
    } else if (dateOfBirth is Timestamp) {
      dob = dateOfBirth.toDate();
    }
    setState(() {
      _name = (d['name'] as String?) ?? (d['userName'] as String?) ?? 'You';
      _avatarIndex = d['avatarIndex'] as int? ?? 0;
      _bio = d['bio'] as String?;
      _dateOfBirth = dob;
      _houseName = (house['name'] as String?) ?? 'Our House';
      _inviteCode = (house['inviteCode'] as String?) ?? '';
      _isOwner = (house['createdBy'] as String?) == widget.userId;
      _loading = false;
    });
  }

  void _open(Widget screen, {bool refreshOnReturn = false}) {
    SoundService.instance.playPop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (refreshOnReturn && mounted) _load();
    });
  }

  void _openAccountEdit() {
    _open(
      ProfileSetupScreen(
        uid: widget.userId,
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        isEditing: true,
      ),
      refreshOnReturn: true,
    );
  }

  void _openFamilyLink() {
    SoundService.instance.playPop();
    HomeFamilyInviteSheet.show(context, _inviteCode);
  }

  void _openHouse() {
    if (_isOwner) {
      _open(
        HouseSettingsScreen(
          houseId: widget.houseId,
          ownerId: widget.userId,
        ),
        refreshOnReturn: true,
      );
    } else {
      _openFamilyLink();
    }
  }

  

  String _fmtDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  void _editBio() {
    final ctrl = TextEditingController(text: _bio ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Bio',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onPanel)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 4,
              maxLength: 120,
              style: GoogleFonts.poppins(color: AppColors.onPanel, fontSize: 14),
              cursorColor: _pink,
              decoration: InputDecoration(
                filled: true,
                fillColor: HomiePalette.current.fieldFill,
                hintText: 'A little about yourself…',
                hintStyle: GoogleFonts.poppins(color: _textSec),
                counterStyle: GoogleFonts.poppins(color: _textSec, fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _pink.withOpacity(0.6)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  SoundService.instance.playPop();
                  final newBio = ctrl.text.trim();
                  await _db.collection('users').doc(widget.userId).update({
                    'bio': newBio.isEmpty ? FieldValue.delete() : newBio,
                  });
                  if (mounted) {
                    setState(() => _bio = newBio.isEmpty ? null : newBio);
                    Navigator.pop(context);
                  }
                },
                child: Text('Save',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.onPanel)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  void _showQr() {
  showModalBottomSheet(
    context: context,
    backgroundColor: _card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dragHandle(),
          const SizedBox(height: 16),
          Text(
            'My profile QR',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onPanel,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: QrImageView(
              data: widget.userId,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onPanel,
            ),
          ),
          Text(
            'member of "$_houseName"',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSec),
          ),
        ],
      ),
    ),
  );
}

  Widget _dragHandle() => Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: HomiePalette.current.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : CustomScrollView(
              slivers: [
                
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      children: [
                        _InfoSection(
                          label: 'PERSONAL',
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Display name',
                              value: _name,
                              onTap: _openAccountEdit,
                              editable: true,
                            ),
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Date of birth',
                              value: _dateOfBirth != null
                                  ? _fmtDob(_dateOfBirth!)
                                  : 'Not set',
                              onTap: _openAccountEdit,
                              editable: true,
                              dimValue: _dateOfBirth == null,
                            ),
                            _InfoRow(
                              icon: Icons.notes_outlined,
                              label: 'Bio',
                              value: (_bio != null && _bio!.isNotEmpty)
                                  ? _bio!
                                  : 'Add a short bio',
                              onTap: _editBio,
                              editable: true,
                              dimValue: _bio == null || _bio!.isEmpty,
                              multiline: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          label: 'HOUSE',
                          children: [
                            if (_isOwner)
                              _InfoRow(
                                icon: Icons.home_outlined,
                                label: 'House Settings',
                                value: _houseName,
                                onTap: _openHouse,
                                editable: true,
                              )
                            else
                              _InfoRow(
                                icon: Icons.home_outlined,
                                label: 'House',
                                value: _houseName,
                                onTap: _openFamilyLink,
                              ),
                            _InfoRow(
                              icon: Icons.qr_code_2_rounded,
                              label: 'Family Link',
                              value: 'Invite housemates',
                              onTap: _openFamilyLink,
                              editable: true,
                            ),
                            _InfoRow(
                              icon: Icons.tag_outlined,
                              label: 'Invite code',
                              value: _inviteCode.isNotEmpty
                                  ? _inviteCode
                                  : '—',
                              onTap: () {
                                if (_inviteCode.isEmpty) return;
                                Clipboard.setData(
                                    ClipboardData(text: _inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied!',
                                        style: GoogleFonts.poppins()),
                                    backgroundColor: _card,
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              trailing: Icon(Icons.copy_rounded,
                                  color: AppColors.onPanelMuted, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          label: 'ACCOUNT',
                          children: [
                            _InfoRow(
                              icon: Icons.lock_outline,
                              label: 'Security',
                              value: 'Password & biometrics',
                              onTap: () =>
                                  _open(const SecuritySettingsScreen()),
                            ),
                            _InfoRow(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              value: 'Manage',
                              onTap: () =>
                                  _open(const NotificationsSettingsScreen()),
                            ),
                            _InfoRow(
                              icon: Icons.visibility_off_outlined,
                              label: 'Privacy',
                              value: 'Manage',
                              onTap: () =>
                                  _open(const PrivacySettingsScreen()),
                            ),
                            _InfoRow(
                                icon: Icons.palette_outlined,
                                label: 'Theme',
                                value: _themeLabel,
                                onTap: () =>
                                    _open(const ThemeSettingsScreen()),
                              ),
                              _InfoRow(
                                icon: Icons.volume_up_outlined,
                                label: 'Sound',
                                value: 'Music & effects volume',
                                onTap: () => _open(const SoundSettingsScreen()),
                              ),
                              _InfoRow(
                                icon: Icons.help_outline_rounded,
                                label: 'Help',
                                value: 'FAQs & support',
                                onTap: () =>
                                    _open(const HelpSettingsScreen()),
                                isLast: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 28),
      decoration: BoxDecoration(
        gradient: HomiePalette.current.useDarkTopPanelImage
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF161823)],
              )
            : HomiePalette.current.topBarGradient,
      ),
      child: Column(
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  SoundService.instance.playPop();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center, 
                  decoration: BoxDecoration(
                    color: AppColors.onPanelDivider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SettingsBackIcon(width: 13, height: 25),
                ),
              ),
              GestureDetector(
                onTap: () {
                  SoundService.instance.playPop();
                  _showQr();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.onPanelDivider,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code_rounded, color: AppColors.onPanelSecondary, size: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          
          GestureDetector(
            onTap: _openAccountEdit,
            child: Stack(
              children: [
                HomeCatAvatar(avatarIndex: _avatarIndex, size: 140),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _pink,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bg, width: 2),
                    ),
                    child: Icon(Icons.edit_rounded,
                        color: AppColors.onPanel, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          
          GestureDetector(
            onTap: _openAccountEdit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, color: _pink, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),

          
          Text(
            _houseName,
            style: GoogleFonts.poppins(fontSize: 14, color: _textSec),
          ),

          if (_bio != null && _bio!.isNotEmpty)
            ...[
              const SizedBox(height: 10),
              Text(
                _bio!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16, color: AppColors.onPanelSecondary, height: 1.5),
              ),
            ],
        ],
    ));
  }
}





class _InfoSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _InfoSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Column(children: children),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool editable;
  final bool dimValue;
  final bool multiline;
  final bool isLast;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.editable = false,
    this.dimValue = false,
    this.multiline = false,
    this.isLast = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: HomiePanel.imageOrCard(
        darkAsset: 'assets/images/BillSubPanel.png',
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () {
          SoundService.instance.playPop();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.onPanelSecondary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.onPanelSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: dimValue ? AppColors.onPanelMuted : AppColors.onPanel,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right_rounded, color: AppColors.onPanelMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}