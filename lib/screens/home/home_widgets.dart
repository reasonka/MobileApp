import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chore_model.dart';
import '../../theme.dart';

/// Design tokens from the Figma MobileApp home screens.
class HomeTokens {
  static const screenBg = Color(0xFF161823);
  static const horizontalPadding = 21.0;
  static const cardRadius = 20.0;
  static const weekPink = Color(0xFFB5509B);
  static const panelTint = Color(0x4D252B4C); // rgba(37,43,76,0.3)
  static const actionButtonBg = Color(0x33252B4C); // rgba(37,43,76,0.2)

  static const cardShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
  );

  static const mainCardGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.8,
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

  static const housemateCardGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.6,
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

  static const xpListGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.8,
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

  static const titleGradient = RadialGradient(
    center: Alignment(-0.82, -0.82),
    radius: 1.6,
    colors: [
      Color(0xFFB721A9),
      Color(0xFFA53D91),
      Color(0xFF925A79),
      Color(0xFF807660),
      Color(0xFF6D9248),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );
}

/// Cat avatar images from Figma (mapped by profile avatarIndex).
class HomeCatAvatar extends StatelessWidget {
  final int avatarIndex;
  final double size;
  final bool showBorder;

  const HomeCatAvatar({
    super.key,
    required this.avatarIndex,
    this.size = 40,
    this.showBorder = true,
  });

  static String assetForIndex(int index) {
    switch (index.clamp(0, 2)) {
      case 1:
        return 'assets/images/home/avatar_blue.png';
      case 2:
        return 'assets/images/home/avatar_blue_wink.png';
      default:
        return 'assets/images/home/avatar_purple.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: HomeTokens.screenBg, width: 2)
            : null,
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: ClipOval(
        child: Image.asset(
          assetForIndex(avatarIndex),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Sticky header: avatar, gradient house title, settings gear.
class HomeHeader extends StatelessWidget {
  final String houseName;
  final int avatarIndex;
  final VoidCallback? onSettingsTap;

  const HomeHeader({
    super.key,
    required this.houseName,
    required this.avatarIndex,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: HomeTokens.panelTint,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [HomeTokens.cardShadow],
        ),
        child: Column(
          children: [
            Row(
              children: [
                HomeCatAvatar(avatarIndex: avatarIndex, size: 40),
                const Spacer(),
                GestureDetector(
                  onTap: onSettingsTap,
                  child: SvgPicture.asset(
                    'assets/images/home/settings.svg',
                    width: 40,
                    height: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  HomeTokens.titleGradient.createShader(bounds),
              child: Text(
                houseName.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeWeekLabel extends StatelessWidget {
  final String label;

  const HomeWeekLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: HomeTokens.weekPink,
      ),
    );
  }
}

/// Pill action button ("New chore" / "New note").
class HomeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HomeActionButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: HomeTokens.actionButtonBg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [HomeTokens.cardShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/home/add_icon.svg',
              width: 31,
              height: 31,
            ),
            const SizedBox(width: 8),
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
    );
  }
}

/// Figma-style chore checkbox (25×25, dark fill, white border).
class HomeChoreCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;

  const HomeChoreCheckbox({
    super.key,
    required this.checked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: HomeTokens.screenBg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: checked
            ? Padding(
                padding: const EdgeInsets.all(2),
                child: SvgPicture.asset(
                  'assets/images/home/checkmark.svg',
                  fit: BoxFit.contain,
                ),
              )
            : null,
      ),
    );
  }
}

/// Main user chore card with avatar perched on top edge.
class HomeMainChoreCard extends StatelessWidget {
  final List<ChoreModel> chores;
  final int avatarIndex;
  final void Function(ChoreModel)? onToggle;

  const HomeMainChoreCard({
    super.key,
    required this.chores,
    required this.avatarIndex,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 25),
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
          decoration: BoxDecoration(
            gradient: HomeTokens.mainCardGradient,
            borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
            boxShadow: const [HomeTokens.cardShadow],
          ),
          child: chores.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No chores this week',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                )
              : _ChoreGrid(
                  chores: chores,
                  onToggle: onToggle,
                ),
        ),
        Positioned(
          top: 0,
          child: HomeCatAvatar(
            avatarIndex: avatarIndex,
            size: 50,
          ),
        ),
      ],
    );
  }
}

class _ChoreGrid extends StatelessWidget {
  final List<ChoreModel> chores;
  final void Function(ChoreModel)? onToggle;

  const _ChoreGrid({required this.chores, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < chores.length; i += 2) {
      final left = chores[i];
      final right = i + 1 < chores.length ? chores[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _ChoreCell(chore: left, onToggle: onToggle)),
            if (right != null)
              Expanded(child: _ChoreCell(chore: right, onToggle: onToggle))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < chores.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }
}

class _ChoreCell extends StatelessWidget {
  final ChoreModel chore;
  final void Function(ChoreModel)? onToggle;

  const _ChoreCell({required this.chore, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chore.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: chore.completed
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
              ),
            ),
          ),
          HomeChoreCheckbox(
            checked: chore.completed,
            onTap: onToggle != null ? () => onToggle!(chore) : null,
          ),
        ],
      ),
    );
  }
}

/// Small housemate chore preview card.
class HomeHousemateCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final List<ChoreModel> chores;
  final VoidCallback onTap;

  const HomeHousemateCard({
    super.key,
    required this.member,
    required this.chores,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarIdx = member['avatarIndex'] as int? ?? 0;
    final incomplete = chores.where((c) => !c.completed).toList();
    final first = incomplete.isNotEmpty ? incomplete.first.title : null;
    final extra = (incomplete.length - 1).clamp(0, 99);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 138,
        padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
        decoration: BoxDecoration(
          gradient: HomeTokens.housemateCardGradient,
          borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
          boxShadow: const [HomeTokens.cardShadow],
        ),
        child: Column(
          children: [
            HomeCatAvatar(avatarIndex: avatarIdx, size: 54),
            const Spacer(),
            if (first != null) ...[
              Text(
                first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (extra > 0)
                Text(
                  '+$extra more',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
            ] else
              Text(
                member['name'] as String? ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Podium illustration from Figma.
class HomePodium extends StatelessWidget {
  const HomePodium({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/home/podium_glow.png',
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 20,
            child: Image.asset(
              'assets/images/home/podium_characters.png',
              height: 117,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP leaderboard list card.
class HomeXpListCard extends StatelessWidget {
  final List<Map<String, dynamic>> rankedMembers;
  final Map<String, int> xpMap;

  const HomeXpListCard({
    super.key,
    required this.rankedMembers,
    required this.xpMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: HomeTokens.xpListGradient,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: Column(
        children: rankedMembers.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final uid = m['userId'] as String;
          final xp = xpMap[uid] ?? 0;
          final isLast = i == rankedMembers.length - 1;

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    HomeCatAvatar(
                      avatarIndex: m['avatarIndex'] as int? ?? 0,
                      size: 42,
                      showBorder: false,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        m['name'] as String? ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '$xp XP',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: Colors.white.withOpacity(0.08),
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Decorative notes banner image from Figma.
class HomeNotesBanner extends StatelessWidget {
  const HomeNotesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/images/home/notes_banner.png',
        width: double.infinity,
        height: 211,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Read-only chore card for housemate overlay.
class HomeReadOnlyChoreCard extends StatelessWidget {
  final List<ChoreModel> chores;

  const HomeReadOnlyChoreCard({super.key, required this.chores});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: HomeTokens.mainCardGradient,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: chores.isEmpty
          ? Text(
              'No chores assigned',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : _ChoreGrid(chores: chores),
    );
  }
}
