import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/note_model.dart';
import '../../services/sound_service.dart';
import '../../services/theme_service.dart';
import '../../theme.dart';


class HomeTokens {
  static Color get screenBg => HomiePalette.current.screenBg;
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

  static RadialGradient get mainChoreGradient =>
      HomiePalette.current.mainChoreGradient;

  static RadialGradient get memberPanelGradient =>
      HomiePalette.current.memberPanelGradient;

  static RadialGradient get leaderboardListGradient =>
      HomiePalette.current.leaderboardListGradient;

  static BoxShadow get cardShadow => HomiePalette.current.cardShadow;

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
  static const fullGroupPicAsset = '$_groupPicDir/group_pic.png';
  static const defaultGroupPic = '$_groupPicDir/cats/purple.png';

  
  static const groupPicCatsPadding = EdgeInsets.fromLTRB(27, 12, 27, 4);
  static const groupPicAspectRatio = 360 / 200;

  
  static String _avatarPicName(int index) => switch (index.clamp(0, 2)) {
        1 => 'blue',
        2 => 'blue_wink',
        _ => 'purple',
      };

  
  static String groupPicAsset(Iterable<int> avatarIndices) {
    final unique = avatarIndices.map((i) => i.clamp(0, 2)).toSet();

    if (unique.isEmpty) return defaultGroupPic;

    // Purple + cyan + blue wink all in the house → combined group pic.
    if (unique.contains(0) && unique.contains(1) && unique.contains(2)) {
      return fullGroupPicAsset;
    }

    if (unique.length == 1) {
      return '$_groupPicDir/cats/${_avatarPicName(unique.first)}.png';
    }

    final sorted = unique.toList()..sort();
    final key = '${_avatarPicName(sorted[0])}_${_avatarPicName(sorted[1])}';
    return switch (key) {
      'purple_blue' => '$_groupPicDir/cats/purple_blue.png',
      'purple_blue_wink' => '$_groupPicDir/cats/purple_blue_wink.png',
      'blue_blue_wink' => '$_groupPicDir/cats/blue_blue_wink.png',
      _ => defaultGroupPic,
    };
  }

  static String groupPicAssetForMembers(List<Map<String, dynamic>> members) {
    return groupPicAsset(
      members.map((m) => m['avatarIndex'] as int? ?? 0),
    );
  }

  

  static const _podiumDir = 'assets/images/home/podium';
  static const podiumGlowAsset = '$_podiumDir/glow.png';
  static const podiumPedestalAsset = '$_podiumDir/pedestal.png';
  static const podiumAspectRatio = 273.875 / 168.821;
  
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

  /// Sticky-note paper tint matching each cat avatar (0 purple, 1 cyan, 2 blue wink).
  static Color stickyNoteColor(int avatarIndex) {
    switch (avatarIndex.clamp(0, 2)) {
      case 1:
        return const Color(0xFF5FE8DC); // cyan cat
      case 2:
        return const Color(0xFF85B8FF); // blue wink cat
      default:
        return const Color(0xFFF5A8E8); // purple cat
    }
  }

  static const stickyNoteSlots = <Alignment>[
    Alignment(-0.82, -0.62),
    Alignment(0.78, -0.55),
    Alignment(-0.72, 0.42),
    Alignment(0.62, 0.28),
    Alignment(-0.05, -0.15),
    Alignment(0.35, 0.55),
  ];
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
        boxShadow: [HomeTokens.cardShadow],
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

/// Group-pic banner with housemate sticky notes overlaid on top.
class HomeStickyNotesBanner extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final List<NoteModel> notes;
  final String currentUserId;
  final VoidCallback onAddNote;
  final Future<void> Function(String noteId) onDeleteNote;

  const HomeStickyNotesBanner({
    super.key,
    required this.members,
    required this.notes,
    required this.currentUserId,
    required this.onAddNote,
    required this.onDeleteNote,
  });

  int _avatarFor(String authorId) {
    for (final m in members) {
      if (m['userId'] == authorId) {
        return m['avatarIndex'] as int? ?? 0;
      }
    }
    return 0;
  }

  void _confirmDelete(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete note?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onPanel,
          ),
        ),
        content: Text(
          'This sticky note will be removed for everyone in your house.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.onPanel.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundService.instance.playUndo();
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.onPanelMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              SoundService.instance.playDelete();
              await onDeleteNote(note.noteId);
            
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: const Color(0xFFE040FB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: HomeTokens.groupPicAspectRatio,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          HomeGroupPic(members: members),
          ...notes.asMap().entries.map((entry) {
            final i = entry.key;
            final note = entry.value;
            final slot = HomeTokens.stickyNoteSlots[
                i % HomeTokens.stickyNoteSlots.length];
            final rotation = ((i % 5) - 2) * 0.05;
            final isOwn = note.authorId == currentUserId;
            final sticky = _StickyNote(
              content: note.content,
              authorName: note.authorName,
              color: HomeTokens.stickyNoteColor(_avatarFor(note.authorId)),
              maxWidth: 108,
              showDeleteHint: isOwn,
            );
            return Align(
              alignment: slot,
              child: Transform.rotate(
                angle: rotation,
                child: isOwn
                    ? GestureDetector(
                        onTap: () {
                          SoundService.instance.playPop();
                          _confirmDelete(context, note);
                        },
                        child: sticky,
                      )
                    : sticky,
              ),
            );
          }),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: Transform.rotate(
                angle: 0.04,
                child: GestureDetector(
                  onTap: () {
                    SoundService.instance.playPop();
                    onAddNote();
                  },
                  child: _StickyNote(
                    content: '',
                    isAddButton: true,
                    color: const Color(0xFFFFF6B3),
                    maxWidth: 72,
                    minHeight: 72,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyNote extends StatelessWidget {
  final String content;
  final String authorName;
  final Color color;
  final double maxWidth;
  final double minHeight;
  final bool isAddButton;
  final bool showDeleteHint;

  const _StickyNote({
    required this.content,
    this.authorName = '',
    required this.color,
    required this.maxWidth,
    this.minHeight = 0,
    this.isAddButton = false,
    this.showDeleteHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minWidth: isAddButton ? maxWidth : 72,
        minHeight: isAddButton ? minHeight : 0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isAddButton ? 0 : 10,
        vertical: isAddButton ? 0 : 8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(2, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: isAddButton
          ? Center(
              child: Icon(
                Icons.add_rounded,
                size: 36,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (authorName.isNotEmpty)
                      Expanded(
                        child: Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    if (showDeleteHint)
                      Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                  ],
                ),
                if (authorName.isNotEmpty) const SizedBox(height: 2),
                Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.82),
                    height: 1.25,
                  ),
                ),
              ],
            ),
    );
  }
}


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
    final isLight = ThemeService.instance.isLight;

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
                child: isLight
                    ? const CustomPaint(
                        painter: _LightPodiumGlowPainter(),
                        child: SizedBox.expand(),
                      )
                    : Image.asset(
                        HomeTokens.podiumGlowAsset,
                        fit: BoxFit.fill,
                      ),
              ),
              Positioned.fromRect(
                rect: pedRect,
                child: isLight
                    ? const CustomPaint(
                        painter: _LightPodiumPedestalPainter(),
                        child: SizedBox.expand(),
                      )
                    : Image.asset(
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

/// Soft lavender→mint semicircle — light variation of the dark teal glow art.
class _LightPodiumGlowPainter extends CustomPainter {
  const _LightPodiumGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 0.52;

    final glowPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.bottomCenter,
        startAngle: 3.14159,
        endAngle: 2 * 3.14159,
        colors: const [
          Color(0x00C8B8E8),
          Color(0x66D4C0F0),
          Color(0x99B8E0E8),
          Color(0xBBD8C8F4),
          Color(0x99C0D8F0),
          Color(0x66D4C0F0),
          Color(0x00C8B8E8),
        ],
        stops: const [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
        transform: const GradientRotation(3.14159),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        3.14159,
        3.14159,
        false,
      )
      ..close();

    // Soft fill wash behind the arc.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.bottomCenter,
          radius: 1.0,
          colors: const [
            Color(0x55E8DCF8),
            Color(0x33D0E8F0),
            Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..shader = glowPaint.shader,
    );

    // Thin highlight line (Figma glow has a bright rim).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.92),
      3.14159 + 0.35,
      0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xAAFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted lilac glass blocks — light variation of the dark pedestal art.
class _LightPodiumPedestalPainter extends CustomPainter {
  const _LightPodiumPedestalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Match dark pedestal proportions: left (2nd), center (1st), right (3rd).
    _drawBlock(
      canvas,
      Rect.fromLTWH(w * 0.02, h * 0.28, w * 0.32, h * 0.72),
      radius: 10,
    );
    _drawBlock(
      canvas,
      Rect.fromLTWH(w * 0.66, h * 0.38, w * 0.32, h * 0.62),
      radius: 10,
    );
    // Center last so it sits in front.
    _drawBlock(
      canvas,
      Rect.fromLTWH(w * 0.28, h * 0.02, w * 0.44, h * 0.98),
      radius: 12,
      highlight: true,
    );
  }

  void _drawBlock(
    Canvas canvas,
    Rect rect, {
    required double radius,
    bool highlight = false,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Soft drop shadow.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x284A3F66)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Body — crisp white glass (reads as object on neutral stage).
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highlight
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF6F4FA),
                  Color(0xFFECE8F4),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF8F6FC),
                  Color(0xFFF0ECF6),
                ],
        ).createShader(rect),
    );

    // Top face sheen.
    final topFace = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topFace, Radius.circular(radius)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.15),
          ],
        ).createShader(topFace),
    );

    // Rim highlight.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = highlight
            ? const Color(0xCCB794F0)
            : const Color(0x99C4B0E0),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class HomeBottomScrollFade extends StatelessWidget {
  const HomeBottomScrollFade({super.key});

  
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
              colors: HomiePalette.current.bottomFadeColors,
              stops: HomiePalette.current.bottomFadeStops,
            ),
          ),
        ),
      ),
    );
  }
}


class HomeHousemateInvitePlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const HomeHousemateInvitePlaceholder({super.key, required this.onTap});

  static const double cardHeight = 138;

 @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundService.instance.playPop();
        onTap();
      },
      child: Container(
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: ThemeService.instance.isLight
            ? AppColors.secondaryCard(radius: 20)
            : BoxDecoration(
                gradient: HomeTokens.memberPanelGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [HomeTokens.cardShadow],
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
                color: AppColors.onPanel,
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HomiePalette.current.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                data: inviteCode,
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
                gradient: isLight
                    ? HomiePalette.lightHeroGradient
                    : null,
                color: isLight ? null : const Color(0xFF1D1D35),
                borderRadius: BorderRadius.circular(16),
                border: isLight
                    ? null
                    : Border.all(
                        color: AppColors.pink.withValues(alpha: 0.3)),
                boxShadow: isLight ? AppColors.heroShadow : null,
              ),
              child: Text(
                inviteCode,
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
          color: AppColors.onPanel,
          letterSpacing: letterSpacing,
          height: 1.0,
        ),
      ),
    );
  }
}


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
    final p = HomiePalette.current;
    final isLight = !p.useDarkTopPanelImage;

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
              color: p.glassButtonFill,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isLight
                    ? AppColors.pink.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.12),
                width: isLight ? 1.5 : 1,
              ),
              boxShadow: isLight
                  ? AppColors.heroShadow
                  : [HomeTokens.cardShadow],
            ),
            child: Row(
              children: [
                const SizedBox(width: 11),
                SvgPicture.asset(
                  'assets/images/home/add_icon.svg',
                  width: 31,
                  height: 31,
                  colorFilter: ColorFilter.mode(
                    AppColors.onGlassIcon,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPanel,
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
