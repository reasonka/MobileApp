//home_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../settings/settings_screen.dart';
import 'home_widgets.dart';


/// Collapsing header matching Figma Home top (88:314) vs scrolled (88:172).
class HomeSliverAppBar extends StatelessWidget {
  final String houseId;
  final String currentUserId;
  final String houseName;
  final String weekRangeLabel;
  final int avatarIndex;

  const HomeSliverAppBar({
    super.key,
    required this.houseId,
    required this.currentUserId,
    required this.houseName,
    required this.weekRangeLabel,
    required this.avatarIndex,
  });

  static const double _expandedBody = 248;
  static const double _collapsedBody = 132;

  // Figma Screen (402×874) — absolute y from top of frame.
  static const double _titleTopExpanded = 135;
  static const double _titleTopCollapsed = 61;
  static const double _avatarTopExpanded = 68;
  static const double _avatarTopCollapsed = 57;
  static const double _settingsTopExpanded = 75;
  static const double _settingsTopCollapsed = 64;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final expandedHeight = _expandedBody - top;
    final collapsedHeight = _collapsedBody - top;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: HomeTokens.screenBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final range = expandedHeight - collapsedHeight;
          final t = range <= 0
              ? 0.0
              : ((constraints.maxHeight - collapsedHeight) / range)
                  .clamp(0.0, 1.0);

          final titleSize = 40.0 + 8.0 * t;
          final titleTop = (_titleTopCollapsed - top) +
              (_titleTopExpanded - _titleTopCollapsed) * t;
          final avatarTop = (_avatarTopCollapsed - top) +
              (_avatarTopExpanded - _avatarTopCollapsed) * t;
          final settingsTop = (_settingsTopCollapsed - top) +
              (_settingsTopExpanded - _settingsTopCollapsed) * t;

          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: t,
                child: SvgPicture.asset(
                  'assets/images/home/top_panel.svg',
                  fit: BoxFit.fill,
                  alignment: Alignment.topCenter,
                ),
              ),
              Opacity(
                opacity: 1 - t,
                child: SvgPicture.asset(
                  'assets/images/home/top_panel_scrolled.svg',
                  fit: BoxFit.fill,
                  alignment: Alignment.topCenter,
                ),
              ),
              Positioned(
                left: HomeTokens.horizontalPadding,
                top: avatarTop,
                child: HomeCatAvatar(
                  avatarIndex: avatarIndex,
                  size: 40,
                ),
              ),
              Positioned(
                left: 70,
                right: 70,
                top: titleTop,
                child: HomeHouseTitle(
                  houseName: houseName,
                  fontSize: titleSize,
                  letterSpacing: -5 * (titleSize / 48),
                ),
              ),
              if (t > 0.35)
                Positioned(
                  left: 0,
                  right: 0,
                  top: titleTop + titleSize + 6,
                  child: Opacity(
                    opacity: t,
                    child: Text(
                      weekRangeLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: HomeTokens.weekLabelColor,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: HomeTokens.horizontalPadding,
                top: settingsTop,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        userId: currentUserId,
                        houseId: houseId,
                      ),
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/home/settings.svg',
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
