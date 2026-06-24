import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sound_service.dart';

/// Design tokens from the Figma Settings screen (node 88:435).
class SettingsTokens {
  static const screenBg = Color(0xFF161823);
  static const horizontalPadding = 20.0;
  static const panelRadius = 20.0;
  static const searchHeight = 61.0;
  static const cardShadow = BoxShadow(
    color: Color(0x40000000),
    offset: Offset(0, 4),
    blurRadius: 4,
  );

  static const panelGradient = RadialGradient(
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
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: SettingsTokens.panelGradient,
        borderRadius: BorderRadius.circular(SettingsTokens.panelRadius),
        boxShadow: const [SettingsTokens.cardShadow],
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
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
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
    return GestureDetector(
      onTap: onTap,
      child: SettingsGradientPanel(
        padding: const EdgeInsets.fromLTRB(24, 22, 20, 22),
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
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your housemates',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
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
