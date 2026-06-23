import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../theme.dart';

/// Design tokens from Figma Home (88:184) and Home scrolled (88:110).
class HomeTokens {
  static const screenBg = Color(0xFF161823);
  static const horizontalPadding = 21.0;
  static const weekLabelColor = Color(0xFFB5509B);

  static const houseTitleGradient = LinearGradient(
    begin: Alignment(-0.9, -0.5),
    end: Alignment(0.9, 0.8),
    colors: [
      Color(0xFFB721A9),
      Color(0xFFA53D91),
      Color(0xFF925A79),
      Color(0xFF807660),
      Color(0xFF6D9248),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static const mainChoreGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.6,
    colors: [
      Color(0xB3AF69F1),
      Color(0xB3DA70D7),
      Color(0xB3AE67BC),
      Color(0xB3815EA0),
      Color(0xB3555485),
      Color(0xB33E5077),
      Color(0xB3284B69),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
  );

  static const memberPanelGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.4,
    colors: [
      Color(0x33AF69F1),
      Color(0x33DA70D7),
      Color(0x33AE67BC),
      Color(0x33815EA0),
      Color(0x33555485),
      Color(0x333E5077),
      Color(0x33284B69),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
  );

  static const leaderboardListGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.6,
    colors: [
      Color(0xB3AF69F1),
      Color(0xB3DA70D7),
      Color(0xB3A47CD7),
      Color(0xB36D89D7),
      Color(0xB3528FD6),
      Color(0xB33795D6),
      Color(0xB31B9BD6),
      Color(0xB30EA1D6),
      Color(0xB300A1D6),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.80, 0.87, 0.93, 0.97, 1.0],
  );

  static const cardShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
  );

  static String avatarAsset(int index) {
    switch (index.clamp(0, 2)) {
      case 1:
        return 'assets/images/home/avatar_blue.png';
      case 2:
        return 'assets/images/home/avatar_blue_wink.png';
      default:
        return 'assets/images/home/avatar_purple.png';
    }
  }

  static const _groupPicDir = 'assets/images/home/group_pics';
  static const groupPicPanelAsset = '$_groupPicDir/group_pic_panel.svg';
  static const defaultGroupPic = '$_groupPicDir/cats/purple.png';

  /// Cat art inset inside the 360×200 GroupPic panel (Figma).
  static const groupPicCatsPadding = EdgeInsets.fromLTRB(27, 12, 27, 4);
  static const groupPicAspectRatio = 360 / 200;

  /// Avatar index: 0 = purple, 1 = blue, 2 = blue wink.
  static String _avatarPicName(int index) => switch (index.clamp(0, 2)) {
        1 => 'blue',
        2 => 'blue_wink',
        _ => 'purple',
      };

  /// Transparent cat art for 1–2 household members.
  static String groupPicAsset(Iterable<int> avatarIndices) {
    final sorted = avatarIndices.map((i) => i.clamp(0, 2)).toList()..sort();

    if (sorted.isEmpty) return defaultGroupPic;

    if (sorted.length == 1 || sorted.first == sorted.last) {
      return '$_groupPicDir/cats/${_avatarPicName(sorted.first)}.png';
    }

    if (sorted.length == 2) {
      final key = '${_avatarPicName(sorted[0])}_${_avatarPicName(sorted[1])}';
      return switch (key) {
        'purple_blue' => '$_groupPicDir/cats/purple_blue.png',
        'purple_blue_wink' => '$_groupPicDir/cats/purple_blue_wink.png',
        'blue_blue_wink' => '$_groupPicDir/cats/blue_blue_wink.png',
        _ => defaultGroupPic,
      };
    }

    return defaultGroupPic;
  }

  static String groupPicAssetForMembers(List<Map<String, dynamic>> members) {
    return groupPicAsset(
      members.map((m) => m['avatarIndex'] as int? ?? 0),
    );
  }

  // ── Podium (Figma Leaderboard 209:234) ─────────────────────────────────────

  static const _podiumDir = 'assets/images/home/podium';
  static const podiumGlowAsset = '$_podiumDir/glow.png';
  static const podiumPedestalAsset = '$_podiumDir/pedestal.png';
  static const podiumAspectRatio = 273.875 / 168.821;
  /// Figma Home scrolled — podium inset x=64 on 402pt screen.
  static const podiumWidthFraction = 273.875 / 402;

  static String podiumCharacterAsset(int avatarIndex) {
    switch (avatarIndex.clamp(0, 2)) {
      case 1:
        return '$_podiumDir/characters/blue.png';
      case 2:
        return '$_podiumDir/characters/blue_wink.png';
      default:
        return '$_podiumDir/characters/purple.png';
    }
  }
}

class HomeCatAvatar extends StatelessWidget {
  final int avatarIndex;
  final double size;
  final double borderWidth;

  const HomeCatAvatar({
    super.key,
    required this.avatarIndex,
    required this.size,
    this.borderWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: HomeTokens.screenBg, width: borderWidth),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: ClipOval(
        child: Image.asset(
          HomeTokens.avatarAsset(avatarIndex),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Household group illustration — panel + transparent cat art per avatars.
class HomeGroupPic extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  const HomeGroupPic({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    final catsAsset = HomeTokens.groupPicAssetForMembers(members);

    return AspectRatio(
      aspectRatio: HomeTokens.groupPicAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            HomeTokens.groupPicPanelAsset,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: HomeTokens.groupPicCatsPadding,
            child: Image.asset(
              catsAsset,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP leaderboard podium — 1st center, 2nd left, 3rd right (Figma 209:234).
class HomePodium extends StatelessWidget {
  final List<Map<String, dynamic>> rankedMembers;

  const HomePodium({super.key, required this.rankedMembers});

  static const _glowHeightFrac = 139.676 / 168.821;
  static const _pedestal = Rect.fromLTWH(0.1266, 0.605, 0.738, 0.395);
  static const _charsArea = Rect.fromLTWH(0.1365, 0.1406, 0.723, 0.692);
  static const _slotLeft = Rect.fromLTWH(0.005, 0.428, 0.295, 0.545);
  static const _slotCenter = Rect.fromLTWH(0.255, 0.002, 0.515, 0.847);
  static const _slotRight = Rect.fromLTWH(0.719, 0.418, 0.300, 0.582);

  @override
  Widget build(BuildContext context) {
    final first = rankedMembers.isNotEmpty ? rankedMembers[0] : null;
    final second = rankedMembers.length > 1 ? rankedMembers[1] : null;
    final third = rankedMembers.length > 2 ? rankedMembers[2] : null;

    return AspectRatio(
      aspectRatio: HomeTokens.podiumAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          Rect toAbs(Rect r) =>
              Rect.fromLTWH(r.left * w, r.top * h, r.width * w, r.height * h);

          final charsRect = toAbs(_charsArea);
          final pedRect = toAbs(_pedestal);

          final characters = [
            _placedCharacter(second, _slotLeft, charsRect),
            _placedCharacter(third, _slotRight, charsRect),
            _placedCharacter(first, _slotCenter, charsRect),
          ].whereType<Widget>();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: h * _glowHeightFrac,
                child: Image.asset(
                  HomeTokens.podiumGlowAsset,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned.fromRect(
                rect: pedRect,
                child: Image.asset(
                  HomeTokens.podiumPedestalAsset,
                  fit: BoxFit.fill,
                ),
              ),
              ...characters,
            ],
          );
        },
      ),
    );
  }

  Widget? _placedCharacter(
    Map<String, dynamic>? member,
    Rect slot,
    Rect charsArea,
  ) {
    if (member == null) return null;

    final avatarIndex = member['avatarIndex'] as int? ?? 0;
    final local = Rect.fromLTWH(
      slot.left * charsArea.width,
      slot.top * charsArea.height,
      slot.width * charsArea.width,
      slot.height * charsArea.height,
    );

    return Positioned(
      left: charsArea.left + local.left,
      top: charsArea.top + local.top,
      width: local.width,
      height: local.height,
      child: Image.asset(
        HomeTokens.podiumCharacterAsset(avatarIndex),
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Bottom fade overlay — Figma Scroll Edge Effect Soft (88:296).
class HomeBottomScrollFade extends StatelessWidget {
  const HomeBottomScrollFade({super.key});

  /// Taller than Figma export so the fade is obvious over scroll content.
  static const double _heightFraction = 0.38;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * _heightFraction;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.68),
                Colors.black.withValues(alpha: 0.88),
                Colors.black.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty housemate slot — matches Figma member panel size (≈159×138).
class HomeHousemateInvitePlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const HomeHousemateInvitePlaceholder({super.key, required this.onTap});

  static const double cardHeight = 138;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: HomeTokens.memberPanelGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [HomeTokens.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.pink.withValues(alpha: 0.9),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              "It's more fun together!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your housemates',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Family invite QR bottom sheet (same flow as Settings → Family Link).
class HomeFamilyInviteSheet {
  HomeFamilyInviteSheet._();

  static void show(BuildContext context, String inviteCode) {
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No invite code found',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: QrImageView(
                data: inviteCode,
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
                border: Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
              ),
              child: Text(
                inviteCode,
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
}

class HomeHouseTitle extends StatelessWidget {
  final String houseName;
  final double fontSize;
  final double letterSpacing;

  const HomeHouseTitle({
    super.key,
    required this.houseName,
    required this.fontSize,
    this.letterSpacing = -5,
  });

  @override
  Widget build(BuildContext context) {
    if (houseName.isEmpty) return const SizedBox.shrink();

    return ShaderMask(
      shaderCallback: (bounds) =>
          HomeTokens.houseTitleGradient.createShader(bounds),
      child: Text(
        houseName.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: letterSpacing,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Fixed glass FAB — Figma NewChoreButton (y≈693, h=45).
class HomeGlassActionButton extends StatelessWidget {
  final String label;
  final double width;
  final VoidCallback onTap;

  const HomeGlassActionButton({
    super.key,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: width,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF252B4C).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [HomeTokens.cardShadow],
            ),
            child: Row(
              children: [
                const SizedBox(width: 11),
                SvgPicture.asset(
                  'assets/images/home/add_icon.svg',
                  width: 31,
                  height: 31,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipe up from the bottom (Instagram vanishing-messages style) to open a note.
class HomeNoteSwipeUpLayer extends StatefulWidget {
  final VoidCallback onTriggered;
  final double navReservedHeight;

  const HomeNoteSwipeUpLayer({
    super.key,
    required this.onTriggered,
    this.navReservedHeight = 89,
  });

  @override
  State<HomeNoteSwipeUpLayer> createState() => _HomeNoteSwipeUpLayerState();
}

class _HomeNoteSwipeUpLayerState extends State<HomeNoteSwipeUpLayer>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 72;
  static const double _maxPull = 110;
  static const double _zoneHeight = 72;

  double _pullExtent = 0;
  late final AnimationController _snapCtrl;
  Animation<double>? _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_snapAnim != null) {
          setState(() => _pullExtent = _snapAnim!.value);
        }
      });
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _snapBack() {
    _snapAnim = Tween<double>(begin: _pullExtent, end: 0).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
    );
    _snapCtrl.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_snapCtrl.isAnimating) return;
    setState(() {
      _pullExtent = (_pullExtent - details.delta.dy).clamp(0, _maxPull);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_pullExtent >= _triggerDistance || velocity < -650) {
      setState(() => _pullExtent = 0);
      widget.onTriggered();
      return;
    }
    _snapBack();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final layerHeight = safeBottom + widget.navReservedHeight + _zoneHeight;
    final hintOpacity = 0.35 + (_pullExtent / _maxPull) * 0.55;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: layerHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: safeBottom + 18),
                child: Opacity(
                  opacity: hintOpacity.clamp(0.0, 1.0),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -_pullExtent),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: safeBottom + widget.navReservedHeight + 8,
                  ),
                  child: Opacity(
                    opacity: (_pullExtent / _triggerDistance).clamp(0.0, 1.0),
                    child: const _NotePeekChip(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotePeekChip extends StatelessWidget {
  const _NotePeekChip();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 165,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFF252B4C).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [HomeTokens.cardShadow],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/home/add_icon.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 6),
              Text(
                'New note',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
