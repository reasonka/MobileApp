import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../login/profile_setup_screen.dart';
import '../profile_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../services/theme_service.dart';
import '../../theme.dart';
import 'settings_detail_screens.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String houseId;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.houseId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _searchCtrl = TextEditingController();

  String _userName = '';
  String _houseName = '';
  String _inviteCode = '';
  int _avatarIndex = 0;
  String _searchQuery = '';
  bool _isOwner = false;

  static Color get _card => HomiePalette.current.cardBg;
  static const _pink = Color(0xFFE040FB);
  static Color get _textSec => AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userDoc = await _db.collection('users').doc(widget.userId).get();
    final houseDoc = await _db.collection('houses').doc(widget.houseId).get();
    if (mounted) {
      setState(() {
        _userName = (userDoc.data()?['name'] as String?) ??
            (userDoc.data()?['userName'] as String?) ??
            'You';
        _houseName = (houseDoc.data()?['name'] as String?) ?? 'Mad House';
        _inviteCode = (houseDoc.data()?['inviteCode'] as String?) ?? '';
        _avatarIndex = userDoc.data()?['avatarIndex'] as int? ?? 0;
        _isOwner =
            (houseDoc.data()?['createdBy'] as String?) == widget.userId;
      });
    }
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

  List<_MenuItem> get _menuItems {
    final items = [
      _MenuItem(
        label: 'Account',
        icon: 'account',
        onTap: () => _open(
          ProfileSetupScreen(
            uid: widget.userId,
            email: _auth.currentUser?.email ?? '',
            isEditing: true,
          ),
          refreshOnReturn: true,
        ),
      ),
      _MenuItem(
        label: 'Notifications',
        icon: 'notifications',
        onTap: () => _open(const NotificationsSettingsScreen()),
      ),
      _MenuItem(
        label: 'Security',
        icon: 'security',
        onTap: () => _open(const SecuritySettingsScreen()),
      ),
      _MenuItem(
        label: 'Privacy',
        icon: 'privacy',
        onTap: () => _open(const PrivacySettingsScreen()),
      ),
      _MenuItem(
        label: 'Theme',
        icon: 'theme',
        onTap: () => _open(const ThemeSettingsScreen()),
      ),
      _MenuItem(
        label: 'Help',
        icon: 'help',
        onTap: () => _open(const HelpSettingsScreen()),
      ),
    ];
    if (_isOwner) {
      items.insert(
        0,
        _MenuItem(
          label: 'House Settings',
          icon: 'house',
          onTap: () {
            SoundService.instance.playPop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HouseSettingsScreen(
                  houseId: widget.houseId,
                  ownerId: widget.userId,
                ),
              ),
            );
          },
        ),
      );
    }
    return items;
  }

  List<_MenuItem> get _filtered => _searchQuery.isEmpty
      ? _menuItems
      : _menuItems
          .where((i) => i.label.toLowerCase().contains(_searchQuery))
          .toList();

  void _toast(String label) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      '$label — coming soon',
      textAlign: TextAlign.center,         
      style: GoogleFonts.poppins(
        fontSize: 18,                      
        color: AppColors.onPanel,
      ),
    ),
    backgroundColor: _card,
    duration: const Duration(seconds: 2),
    padding: const EdgeInsets.symmetric(  
      horizontal: 24,
      vertical: 20,
    ),
    behavior: SnackBarBehavior.floating,  
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ));
}

  void _showProfileQR() {
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
              _userName,
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

  void _showFamilyQR() {
    if (_inviteCode.isEmpty) {
      _toast('No invite code found');
      return;
    }
    final isLight = ThemeService.instance.isLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
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
              'Family link',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share this QR to invite housemates',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : HomiePalette.current.surfaceBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HomiePalette.current.cardBorder),
                boxShadow: isLight ? [HomiePalette.current.cardShadow] : null,
              ),
              child: QrImageView(
                data: _inviteCode,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: isLight ? HomiePalette.lightHeroGradient : null,
                color: isLight ? null : const Color(0xFF1D1D35),
                borderRadius: BorderRadius.circular(16),
                border: isLight
                    ? null
                    : Border.all(color: _pink.withValues(alpha: 0.3)),
                boxShadow: isLight ? AppColors.heroShadow : null,
              ),
              child: Text(
                _inviteCode,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onHero,
                  letterSpacing: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveHouse() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded,
                  color: Colors.orangeAccent, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave "$_houseName"?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onPanel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOwner
                  ? "You're the owner. The house will remain with its other members. "
                      "Use the invite code to rejoin."
                  : "You'll need the invite code to rejoin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _textSec,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.onPanelDivider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      SoundService.instance.playPop();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: _textSec,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      SoundService.instance.playPop();
                      Navigator.pop(context);
                      await FirestoreService()
                          .leaveHouse(widget.userId, widget.houseId);
                      // AuthGate reacts automatically once houseId is cleared.
                    },
                    child: Text(
                      'Leave',
                      style: GoogleFonts.poppins(
                        color: AppColors.onPanel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Log out?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onPanel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll need your invite code to rejoin your house.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _textSec,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.onPanelDivider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      SoundService.instance.playPop();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: _textSec,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      SoundService.instance.playPop();
                      Navigator.pop(context);
                      await _auth.signOut();
                    },
                    child: Text(
                      'Log out',
                      style: GoogleFonts.poppins(
                        color: AppColors.onPanel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
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
      backgroundColor: SettingsTokens.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: SettingsTokens.horizontalPadding,
          ),
          children: [
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SettingsBackIcon(width: 13, height: 25),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsGradientPanel(
              height: SettingsTokens.searchHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SettingsIcon(assetName: 'search', size: 27),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.poppins(
                        color: AppColors.onPanelSecondary,
                        fontSize: 20,
                      ),
                      cursorColor: AppColors.onPanel,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.onPanelSecondary,
                          fontSize: 20,
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.onPanelMuted,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
  onTap: () {
    SoundService.instance.playPop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userId: widget.userId,
          houseId: widget.houseId,
        ),
      ),
    );
  },
  child: Row(
    children: [
      Container(
        width: 61,
        height: 61,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.onPanel, width: 2),
          boxShadow: [SettingsTokens.cardShadow],
        ),
        child: ClipOval(
          child: Image.asset(
            SettingsTokens.avatarAsset(_avatarIndex),
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userName.isEmpty ? '...' : _userName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onPanel,
              ),
            ),
            Text(
              'member of "$_houseName"',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: AppColors.onPanel,
              ),
            ),
          ],
        ),
      ),
      
      GestureDetector(
        onTap: () {
            SoundService.instance.playPop();
            _showProfileQR();
          },
        child: Image.asset(
          'assets/images/settings/profile_qr_icon.png',
          width: 42,
          height: 42,
          fit: BoxFit.contain,
        ),
      ),
    ],
  ),
),
            const SizedBox(height: 18),
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No results',
                    style: GoogleFonts.poppins(
                      color: AppColors.onPanelMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ..._filtered.map(
                (item) => SettingsMenuRow(
                  iconAssetName: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                ),
              ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              SettingsFamilyLinkCard(onTap: () {
                SoundService.instance.playPop();
                _showFamilyQR();
              }),
              const SizedBox(height: 20),
              SettingsMenuRow(
                iconAssetName: 'add_account',
                label: 'Add account',
                onTap: () => _open(AddAccountSettingsScreen(
                  currentUserId: widget.userId,
                  currentEmail: _auth.currentUser?.email ?? '',
                  userName: _userName,
                  avatarIndex: _avatarIndex,
                )),
              ),
              SettingsMenuRow(
                iconAssetName: 'logout',
                label: 'Leave House',
                onTap: () {
                  SoundService.instance.playDelete();
                  _confirmLeaveHouse();
                },
              ),
              SettingsMenuRow(
                iconAssetName: 'logout',
                label: 'Log Out',
                onTap: () {
                  SoundService.instance.playDelete();
                  _confirmLogout();
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
