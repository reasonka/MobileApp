import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../profile_screen.dart';
import '../../services/sound_service.dart';
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

  static const _card = Color(0xFF1A1A2E);
  static const _pink = Color(0xFFE040FB);
  static const _textSec = Color(0xFFB0ADCC);

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
      });
    }
  }

  List<_MenuItem> get _menuItems => [
        _MenuItem(label: 'Account', icon: 'account', onTap: () => _toast('Account')),
        _MenuItem(
          label: 'Notifications',
          icon: 'notifications',
          onTap: () => _toast('Notifications'),
        ),
        _MenuItem(
          label: 'Security',
          icon: 'security',
          onTap: () => _toast('Security'),
        ),
        _MenuItem(
          label: 'Privacy',
          icon: 'privacy',
          onTap: () => _toast('Privacy'),
        ),
        _MenuItem(label: 'Theme', icon: 'theme', onTap: () => _toast('Theme')), 
        _MenuItem(label: 'Help', icon: 'help', onTap: () => _toast('Help')),
      ];

  List<_MenuItem> get _filtered => _searchQuery.isEmpty
      ? _menuItems
      : _menuItems
          .where((i) => i.label.toLowerCase().contains(_searchQuery))
          .toList();

  void _toast(String label) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      '$label — coming soon',
      textAlign: TextAlign.center,         // ← center text
      style: GoogleFonts.poppins(
        fontSize: 18,                      // ← bigger text
        color: Colors.white,
      ),
    ),
    backgroundColor: _card,
    duration: const Duration(seconds: 2),
    padding: const EdgeInsets.symmetric(  // ← bigger popup
      horizontal: 24,
      vertical: 20,
    ),
    behavior: SnackBarBehavior.floating,  // ← floating looks better when bigger
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
                color: Colors.white,
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
                color: Colors.white,
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
              'Family link',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Share this QR to invite housemates',
              style: GoogleFonts.poppins(fontSize: 13, color: _textSec),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: QrImageView(
                data: _inviteCode,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _pink.withOpacity(0.3)),
              ),
              child: Text(
                _inviteCode,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
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
                color: Colors.white,
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
                      side: BorderSide(color: Colors.white.withOpacity(0.12)),
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
                        color: Colors.white,
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
          color: const Color(0xFF2E2E50),
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
                  child: SvgPicture.asset(
                    SettingsTokens.iconAsset('back'),
                    width: 13,
                    height: 25,
                  ),
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
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 20,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
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
                        color: Colors.white.withOpacity(0.5),
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
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [SettingsTokens.cardShadow],
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
                color: Colors.white,
              ),
            ),
            Text(
              'member of "$_houseName"',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      // Keep this specific icon button for the QR sheet
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
                      color: Colors.white38,
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
                onTap: () => _toast('Add account'),
              ),
              SettingsMenuRow(
                iconAssetName: 'logout',
                label: 'Log Out',
                onTap: _confirmLogout,
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
