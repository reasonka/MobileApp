import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/login/family_setup_screen.dart';
import 'package:mobile_app/services/firestore_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _bg      = Color(0xFF0D0D1A);
const _card    = Color(0xFF1A1A2E);
const _pill    = Color(0xFF1D1D35);
const _border  = Color(0xFF2E2E50);
const _pink    = Color(0xFFE040FB);
const _purple  = Color(0xFF7B2DBD);
const _textPri = Color(0xFFFFFFFF);
const _textSec = Color(0xFFB0ADCC);
const _textMut = Color(0xFF6B6892);

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
  final _db         = FirebaseFirestore.instance;
  final _auth       = FirebaseAuth.instance;
  final _searchCtrl = TextEditingController();

  String _userName   = '';
  String _houseName  = '';
  String _inviteCode = '';
  String _searchQuery = '';

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
    final userDoc  = await _db.collection('users').doc(widget.userId).get();
    final houseDoc = await _db.collection('houses').doc(widget.houseId).get();
    if (mounted) {
      setState(() {
        _userName   = (userDoc.data()?['name'] as String?)
                   ?? (userDoc.data()?['userName'] as String?)
                   ?? 'You';
        _houseName  = (houseDoc.data()?['name'] as String?) ?? 'Mad House';
        _inviteCode = (houseDoc.data()?['inviteCode'] as String?) ?? '';
      });
    }
  }

  // ── Menu items definition ──────────────────────────────────────────────────

  List<_MenuItem> get _menuItems => [
    _MenuItem(
      label: 'Account',
      icon: Icons.manage_accounts_outlined,
      onTap: () => _toast('Account'),
    ),
    _MenuItem(
      label: 'Notifications',
      icon: Icons.notifications_outlined,
      onTap: () => _toast('Notifications'),
    ),
    _MenuItem(
      label: 'Security',
      icon: Icons.gpp_bad_outlined,
      onTap: () => _toast('Security'),
    ),
    _MenuItem(
      label: 'Privacy',
      icon: Icons.do_not_disturb_on_outlined,
      onTap: () => _toast('Privacy'),
    ),
    _MenuItem(
      label: 'Theme',
      icon: Icons.palette_outlined,
      onTap: () => _showThemeSheet(),
    ),
    _MenuItem(
      label: 'Help',
      icon: Icons.help_outline_rounded,
      onTap: () => _toast('Help'),
    ),
    _MenuItem(
      label: 'Leave House',
      icon: Icons.meeting_room_outlined,
      onTap: () async {
                      Navigator.pop(context); // Close the dialog
                      
                      try {
                        // 1. Trigger the batch update in your service
                        await FirestoreService().leaveHouse(widget.userId, widget.houseId);
                        
                        // 2. Force navigation back to the Setup Screen
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => FamilySetupScreen(
                                uid: widget.userId,
                                userName: _userName,
                              ),
                            ),
                            (route) => false, // Clears the entire navigation stack
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not leave house: $e',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }, // Triggers the new leave dialog
    ),
    _MenuItem(
      label: 'Help',
      icon: Icons.help_outline_rounded,
      onTap: () => _toast('Help'),
    ),
  ];


  List<_MenuItem> get _filtered => _searchQuery.isEmpty
      ? _menuItems
      : _menuItems
          .where((i) => i.label.toLowerCase().contains(_searchQuery))
          .toList();

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toast(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label — coming soon',
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: _card,
      duration: const Duration(seconds: 2),
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
            Text('My profile QR',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri)),
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
            Text(_userName,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPri)),
            Text('member of "$_houseName"',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _textSec)),
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
            Text('Family link',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri)),
            const SizedBox(height: 6),
            Text('Share this QR to invite housemates',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _textSec)),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _pill,
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

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _dragHandle()),
            const SizedBox(height: 16),
            Text('Theme',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri)),
            const SizedBox(height: 20),
            _themeOption(Icons.dark_mode_outlined, 'Dark', true),
            _themeOption(Icons.light_mode_outlined, 'Light', false),
            _themeOption(
                Icons.phone_android_outlined, 'System default', false),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(IconData icon, String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? _pink.withOpacity(0.12) : _pill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected ? _pink.withOpacity(0.4) : _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? _pink : _textSec, size: 20),
          const SizedBox(width: 14),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? _pink : _textPri)),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_rounded, color: _pink, size: 18),
        ],
      ),
    );
  }
void _confirmLeaveHouse() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.home_work_outlined,
                  color: Colors.orangeAccent, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Leave House?',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri)),
            const SizedBox(height: 8),
            Text(
              "You will need a new invite code to join another home.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: _textSec, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            color: _textSec,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      // Remove the houseId from the user's document
                      await _db.collection('users').doc(widget.userId).update({
                        'houseId': FieldValue.delete(),
                      });
                      // AuthGate will detect this and redirect to FamilySetupScreen
                    },
                    child: Text('Leave',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Log out?',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri)),
            const SizedBox(height: 8),
            Text(
              "You'll need your invite code to rejoin your house.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: _textSec, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.12)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            color: _textSec,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _auth.signOut();
                      // AuthGate will redirect automatically
                    },
                    child: Text('Log out',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
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
            color: _border, borderRadius: BorderRadius.circular(2)),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 12),

            // ── Back button ──────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _textPri,
                    size: 22),
              ),
            ),
            const SizedBox(height: 20),

            // ── Search bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D1370), Color(0xFF7B2DBD)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 14),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: GoogleFonts.poppins(
                            color: Colors.white60, fontSize: 14),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchCtrl.clear(),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white60, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Profile row ──────────────────────────────────────────
            GestureDetector(
              onTap: _showProfileQR,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6A1B9A), _pink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.pets_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName.isEmpty ? '...' : _userName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPri,
                          ),
                        ),
                        Text(
                          'member of "$_houseName"',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: _textSec),
                        ),
                      ],
                    ),
                  ),
                  // QR thumbnail
                  GestureDetector(
                    onTap: _showProfileQR,
                    child: QrImageView(
                      data: widget.userId.isEmpty
                          ? 'placeholder'
                          : widget.userId,
                      version: QrVersions.auto,
                      size: 44,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Menu items ───────────────────────────────────────────
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No results',
                      style: GoogleFonts.poppins(
                          color: _textMut, fontSize: 14)),
                ),
              )
            else
              ...List.generate(_filtered.length, (i) {
                final item = _filtered[i];
                return _buildMenuItem(item);
              }),

            const SizedBox(height: 20),

            // ── Family Link card ─────────────────────────────────────
            if (_searchQuery.isEmpty)
              GestureDetector(
                onTap: _showFamilyQR,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D1370), Color(0xFF7B2DBD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Family Link',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your housemates',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      // QR icon frame
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: _inviteCode.isEmpty
                            ? const Icon(Icons.qr_code_2_rounded,
                                color: Colors.white54, size: 44)
                            : QrImageView(
                                data: _inviteCode,
                                version: QrVersions.auto,
                                size: 64,
                                backgroundColor: Colors.transparent,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.white,
                                ),
                                dataModuleStyle:
                                    const QrDataModuleStyle(
                                  dataModuleShape:
                                      QrDataModuleShape.square,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_searchQuery.isEmpty) const SizedBox(height: 28),

            // ── Add account ──────────────────────────────────────────
            if (_searchQuery.isEmpty ||
                'add account'.contains(_searchQuery))
              _buildBottomItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add account',
                onTap: () => _toast('Add account'),
              ),

            const SizedBox(height: 4),

            // ── Log out ──────────────────────────────────────────────
            if (_searchQuery.isEmpty ||
                'log out'.contains(_searchQuery))
              _buildBottomItem(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                onTap: _confirmLogout,
                danger: false,
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Menu item row ──────────────────────────────────────────────────────────

  Widget _buildMenuItem(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(item.icon, color: _textPri, size: 22),
            const SizedBox(width: 18),
            Text(
              item.label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textPri,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom item (add account / log out) ────────────────────────────────────

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                color: danger ? Colors.redAccent : _textPri,
                size: 22),
            const SizedBox(width: 18),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: danger ? Colors.redAccent : _textPri,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────────

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

// ── Theme option row ───────────────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFE040FB).withOpacity(0.12)
            : const Color(0xFF1D1D35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? const Color(0xFFE040FB).withOpacity(0.4)
              : const Color(0xFF2E2E50),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: selected
                  ? const Color(0xFFE040FB)
                  : const Color(0xFFB0ADCC),
              size: 20),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? const Color(0xFFE040FB) : Colors.white,
            ),
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_rounded,
                color: Color(0xFFE040FB), size: 18),
        ],
      ),
    );
  }
}