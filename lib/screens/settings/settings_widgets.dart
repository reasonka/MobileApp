import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sound_service.dart';
import '../../services/theme_service.dart';
import '../../theme.dart';


class SettingsTokens {
  static Color get screenBg => HomiePalette.current.screenBg;
  static const horizontalPadding = 20.0;
  static const panelRadius = 20.0;
  static const searchHeight = 61.0;
  static BoxShadow get cardShadow => HomiePalette.current.cardShadow;

  static RadialGradient get panelGradient =>
      HomiePalette.current.panelGradient;

  static String iconAsset(String name) => 'assets/images/settings/$name.svg';

  static String avatarAsset(int avatarIndex) {
    switch (avatarIndex.clamp(0, 2)) {
      case 1:
        return 'assets/images/home/avatar_blue.png';
      case 2:
        return 'assets/images/home/avatar_blue_wink.png';
      default:
        return 'assets/images/home/avatar_purple.png';
    }
  }
}

class SettingsIcon extends StatelessWidget {
  final String assetName;
  final double size;

  const SettingsIcon({
    super.key,
    required this.assetName,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      SettingsTokens.iconAsset(assetName),
      width: size,
      height: size,
      colorFilter: ThemeService.instance.isLight
          ? ColorFilter.mode(AppColors.onPanelSecondary, BlendMode.srcIn)
          : null,
    );
  }
}

class SettingsBackIcon extends StatelessWidget {
  final double width;
  final double height;

  const SettingsBackIcon({super.key, this.width = 13, this.height = 25});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      SettingsTokens.iconAsset('back'),
      width: width,
      height: height,
      colorFilter: ThemeService.instance.isLight
          ? ColorFilter.mode(AppColors.onPanel, BlendMode.srcIn)
          : null,
    );
  }
}

class SettingsGradientPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  const SettingsGradientPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeService.instance.isLight;
    return Container(
      height: height,
      padding: padding,
      decoration: isLight
          ? AppColors.secondaryCard(radius: SettingsTokens.panelRadius)
          : BoxDecoration(
              gradient: SettingsTokens.panelGradient,
              borderRadius:
                  BorderRadius.circular(SettingsTokens.panelRadius),
              boxShadow: [SettingsTokens.cardShadow],
            ),
      child: child,
    );
  }
}

class SettingsMenuRow extends StatelessWidget {
  final String iconAssetName;
  final String label;
  final VoidCallback onTap;

  const SettingsMenuRow({
    super.key,
    required this.iconAssetName,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundService.instance.playPop();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: SettingsIcon(assetName: iconAssetName),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsFamilyLinkCard extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsFamilyLinkCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeService.instance.isLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 20, 22),
        decoration: BoxDecoration(
          gradient: isLight
              ? HomiePalette.lightHeroGradient
              : SettingsTokens.panelGradient,
          borderRadius: BorderRadius.circular(SettingsTokens.panelRadius),
          boxShadow: AppColors.heroShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Link',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onHero,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your housemates',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onHeroSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 118,
              height: 118,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Image.asset(
                  'assets/images/settings/family_qr_frame.png',
                  width: 118,
                  height: 118,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
