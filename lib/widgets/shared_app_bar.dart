import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/home/home_widgets.dart';
import '../screens/profile_screen.dart';
import '../../services/sound_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class HouseAppBar extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final String weekRangeLabel;
  final String? houseName;
  final int? avatarIndex;
  final VoidCallback? onSettingsTap;

  const HouseAppBar({
    super.key,
    required this.houseId,
    required this.currentUserId,
    required this.weekRangeLabel,
    this.houseName,
    this.avatarIndex,
    this.onSettingsTap,
  });

  @override
  State<HouseAppBar> createState() => _HouseAppBarState();
}

class _HouseAppBarState extends State<HouseAppBar> {
  final FirestoreService _fs = FirestoreService();
  String _houseName = '';
  int _avatarIndex = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    if (widget.houseName != null) _houseName = widget.houseName!;
    if (widget.avatarIndex != null) _avatarIndex = widget.avatarIndex!;
    _listenToProfile();
    if (widget.houseName == null || widget.avatarIndex == null) _load();
  }

  void _listenToProfile() {
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        _avatarIndex = data['avatarIndex'] as int? ?? 0;
      });
    });
  }

  Future<void> _loadHouseName() async {
    final house = await _fs.getHouseData(widget.houseId);
    if (mounted) {
      setState(() {
        _houseName = (house?['name'] as String?) ?? 'Our House';
      });
    }
  }

  @override
  void didUpdateWidget(HouseAppBar old) {
    super.didUpdateWidget(old);
    if (widget.houseName != null) _houseName = widget.houseName!;
    if (widget.avatarIndex != null) _avatarIndex = widget.avatarIndex!;
  }
      @override
        void dispose() {
          _sub?.cancel();
          super.dispose();
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
        if (widget.houseName == null) {
          _houseName = (house?['name'] as String?) ?? 'Our House';
        }
        if (widget.avatarIndex == null) {
          _avatarIndex = me['avatarIndex'] as int? ?? 0;
        }
      });
    }
  }

@override
Widget build(BuildContext context) {
  final double statusBarHeight = MediaQuery.of(context).padding.top;
  final double toolbarHeight = _houseName.length > 14 ? 75.0 : 30.0;

  return SizedBox(
    height: toolbarHeight + statusBarHeight,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/TopPanel.png',
                fit: BoxFit.fill,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              top: statusBarHeight,
              bottom: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 16),
                  GestureDetector(
                      onTap: () {
                        SoundService.instance.playPop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              userId: widget.currentUserId,
                              houseId: widget.houseId,
                            ),
                          ),
                        );
                      },
                      child: HomeCatAvatar(avatarIndex: _avatarIndex, size: 42),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _houseName.isEmpty
                        ? const SizedBox.shrink()
                        : ShaderMask(
                            shaderCallback: (bounds) =>
                                HomeTokens.houseTitleGradient.createShader(bounds),
                            child: Text(
                              _houseName.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: _houseName.length > 14
                                    ? _houseName.length > 20
                                        ? 13.0
                                        : 30.0
                                    : 40.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing:
                                    _houseName.length > 14 ? -0.5 : -2.0,
                                height: 1.1,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onSettingsTap ??
                      () {
                        SoundService.instance.playPop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              userId: widget.currentUserId,
                              houseId: widget.houseId,
                            ),
                          ),
                        );
                      },
                    child: SvgPicture.asset(
                      'assets/images/home/settings.svg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}}