import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/firestore_service.dart';
import '../screens/home/home_widgets.dart';
import '../screens/settings/settings_widgets.dart';

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

  
  static const _bg        = Color(0xFF161823);
  static const _card      = Color(0xFF1A1A2E);
  static const _pink      = Color(0xFFE040FB);
  static const _textSec   = Color(0xFFB0ADCC);
  static const _divider   = Color(0xFF2A2A3E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userDoc  = await _db.collection('users').doc(widget.userId).get();
    final houseDoc = await _db.collection('houses').doc(widget.houseId).get();
    if (!mounted) return;
    final d = userDoc.data() ?? {};
    setState(() {
      _name        = (d['name'] as String?) ?? (d['userName'] as String?) ?? 'You';
      _avatarIndex = d['avatarIndex'] as int? ?? 0;
      _bio         = d['bio'] as String?;
      final dob    = d['dateOfBirth'];
      if (dob is Timestamp) _dateOfBirth = dob.toDate();
      _houseName   = (houseDoc.data()?['name'] as String?) ?? 'Our House';
      _inviteCode  = (houseDoc.data()?['inviteCode'] as String?) ?? '';
      _loading     = false;
    });
  }

  

  String _fmtDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  void _comingSoon(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚧', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Coming soon',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '$feature will be available in a future update.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: _textSec, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Got it',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  void _editName() {
    final ctrl = TextEditingController(text: _name);
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
            Text('Display name',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              cursorColor: _pink,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                hintText: 'Your name',
                hintStyle: GoogleFonts.poppins(color: _textSec),
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
            const SizedBox(height: 20),
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
                  final newName = ctrl.text.trim();
                  if (newName.isEmpty) return;
                  await _db.collection('users').doc(widget.userId).update({
                    'name': newName,
                  });
                  if (mounted) {
                    setState(() => _name = newName);
                    Navigator.pop(context);
                  }
                },
                child: Text('Save',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

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
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 4,
              maxLength: 120,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              cursorColor: _pink,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
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
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Future<void> _editDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _pink,
            onPrimary: Colors.white,
            surface: Color(0xFF1D1D35),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0D0D1A)),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    await _db.collection('users').doc(widget.userId).update({
      'dateOfBirth': Timestamp.fromDate(picked),
    });
    setState(() => _dateOfBirth = picked);
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
            _name,
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

  

  void _pickAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _divider, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Choose avatar',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                final selected = _avatarIndex == i;
                return GestureDetector(
                  onTap: () async {
                    await _db
                        .collection('users')
                        .doc(widget.userId)
                        .update({'avatarIndex': i});
                    if (mounted) {
                      setState(() => _avatarIndex = i);
                      Navigator.pop(context);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? _pink : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: HomeCatAvatar(avatarIndex: i, size: 90),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
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
                              onTap: _editName,
                              editable: true,
                            ),
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Date of birth',
                              value: _dateOfBirth != null
                                  ? _fmtDob(_dateOfBirth!)
                                  : 'Not set',
                              onTap: _editDob,
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
                            _InfoRow(
                              icon: Icons.home_outlined,
                              label: 'House',
                              value: _houseName,
                              onTap: () => _comingSoon('Changing your house'),
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
                              trailing: const Icon(Icons.copy_rounded,
                                  color: Color(0xFF555577), size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          label: 'ACCOUNT',
                          children: [
                            _InfoRow(
                              icon: Icons.lock_outline,
                              label: 'Password',
                              value: '••••••••',
                              onTap: () => _comingSoon('Password change'),
                            ),
                            _InfoRow(
                              icon: Icons.notifications_outlined,
                              label: 'Notifications',
                              value: 'Manage',
                              onTap: () => _comingSoon('Notifications'),
                            ),
                            _InfoRow(
                              icon: Icons.palette_outlined,
                              label: 'Theme',
                              value: 'Dark',
                              onTap: () => _comingSoon('Theme selection'),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF161823)],
        ),
      ),
      child: Column(
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center, 
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    SettingsTokens.iconAsset('back'),
                    width: 13,
                    height: 25,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showQr,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: Colors.white70, size: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          
          GestureDetector(
            onTap: _pickAvatar,
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
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          
          GestureDetector(
            onTap: _editName,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                    fontSize: 16, color: Colors.white70, height: 1.5),
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
              color: const Color(0xFF555577),
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
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/BillSubPanel.png'),
          fit: BoxFit.fill, 
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFB0ADCC), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14, 
                        color: const Color(0xFFB0ADCC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18, 
                        color: dimValue ? const Color(0xFF555577) : Colors.white,
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
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF555577), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}