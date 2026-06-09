import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import 'settings_screen.dart';

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
  final _fs = FirestoreService();
  String _houseName = '';
  int _avatarIndex = 0;

  static const _gradients = [
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

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[_avatarIndex.clamp(0, 2)];

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.pets_rounded,
                color: Colors.white, size: 19),
          ),
        ),
      ),
      title: _houseName.isEmpty
          ? const SizedBox.shrink()
          : ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFFFFD54F)],
              ).createShader(bounds),
              child: Text(
                _houseName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.pink, size: 26),
            // In shared_app_bar.dart — replace the onPressed
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SettingsScreen(
      userId: widget.currentUserId,
      houseId: widget.houseId,
    ),
  ),
),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: Column(
          children: [
            Text(
              widget.weekRangeLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.pink.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(
              color: Colors.white12,
              height: 1,
              indent: 24,
              endIndent: 24,
            ),
          ],
        ),
      ),
    );
  }
}