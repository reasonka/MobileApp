import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../screens/settings/settings_screen.dart';

class HouseAppBar extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final String weekRangeLabel;
  final VoidCallback? onSettingsTap;

  const HouseAppBar({
    super.key,
    required this.houseId,
    required this.currentUserId,
    required this.weekRangeLabel,
    this.onSettingsTap,
  });

  @override
  State<HouseAppBar> createState() => _HouseAppBarState();
}

class _HouseAppBarState extends State<HouseAppBar> {
  final FirestoreService _fs = FirestoreService();
  String _houseName = '';
  int _avatarIndex = 0;

  static const List<List<Color>> _gradients = [
    [Color(0xFF6A1B9A), Color(0xFFE040FB)],
    [Color(0xFF1B5E20), Color(0xFF00C9A7)],
    [Color(0xFF1A237E), Color(0xFF448AFF)],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final house = await _fs.getHouseData(widget.houseId);
    final members = await _fs.getHouseMemberDetails(widget.houseId);
    final me = members.firstWhere(
      (m) => m['userId'] == widget.currentUserId,
      orElse: () => {'avatarIndex': 0},
    );
    if (mounted) {
      setState(() {
        _houseName = (house?['name'] as String?) ?? 'Our House';
        _avatarIndex = me['avatarIndex'] as int? ?? 0;
      });
    }
  }

 // Replace the title, leading, and actions with this approach:

@override
Widget build(BuildContext context) {
  final List<Color> colors = _gradients[_avatarIndex.clamp(0, 2)];
  final double statusBarHeight = MediaQuery.of(context).padding.top;
  final double toolbarHeight = 70.0;


  return SliverAppBar(
    pinned: true,
    automaticallyImplyLeading: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: toolbarHeight + statusBarHeight,
    // Remove title, leading, actions entirely — put everything in flexibleSpace
    flexibleSpace: Stack(
      children: [
        // ── Background image ──────────────────────────────────────────
        Positioned.fill(
          child: Image.asset(
            'assets/images/TopPanel.png',
            fit: BoxFit.fill,
          ),
        ),

        // ── Avatar (leading) ──────────────────────────────────────────
        Positioned(
          left: 16,
          top: statusBarHeight + (toolbarHeight - 42) / 2,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.pets_rounded, color: Colors.white, size: 19),
          ),
        ),

        // ── House name (centered) ─────────────────────────────────────
        Positioned(
          left: 70,
          right: 70,
          top: statusBarHeight,
          height: toolbarHeight,
          child: Center(
            child: _houseName.isEmpty
                ? const SizedBox.shrink()
                : ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE040FB), Color(0xFFFFD54F)],
                    ).createShader(bounds),
                    child: Text(
                      _houseName.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                    ),
                  ),
          ),
        ),

        // ── Settings icon (trailing) ──────────────────────────────────
        Positioned(
          right: 12,
          top: statusBarHeight + (toolbarHeight - 32) / 2,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  userId: widget.currentUserId,
                  houseId: widget.houseId,
                ),
              ),
            ),
            child: Image.asset(
              'assets/images/Settings.png',
              width: 32,
              height: 32,
            ),
          ),
        ),
      ],
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(0),
      child: SizedBox.shrink(),
    ),
  );
}
}