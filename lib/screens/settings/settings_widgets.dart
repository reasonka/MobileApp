import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../home/home_widgets.dart';

class SettingsTokens {
  static const horizontalPadding = 20.0;
  static const rowHeight = 43.0;
  static const searchHeight = 61.0;
  static const familyCardHeight = 133.0;
  static const cardRadius = HomeTokens.cardRadius;
}

class SettingsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const SettingsSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SettingsTokens.searchHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: HomeTokens.mainCardGradient,
        borderRadius: BorderRadius.circular(SettingsTokens.cardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/settings/search.svg',
            width: 27,
            height: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.7),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsAccountHeader extends StatelessWidget {
  final String userName;
  final String houseName;
  final int avatarIndex;
  final String? inviteCode;

  const SettingsAccountHeader({
    super.key,
    required this.userName,
    required this.houseName,
    required this.avatarIndex,
    this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [HomeTokens.cardShadow],
          ),
          child: HomeCatAvatar(
            avatarIndex: avatarIndex,
            size: 61,
            showBorder: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'member of "$houseName"',
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (inviteCode != null && inviteCode!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: QrImageView(
              data: inviteCode!,
              version: QrVersions.auto,
              size: 42,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(2),
            ),
          ),
      ],
    );
  }
}

class SettingsMenuRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback? onTap;

  const SettingsMenuRow({
    super.key,
    required this.iconAsset,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: SettingsTokens.rowHeight,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: SvgPicture.asset(
                iconAsset,
                height: 28,
                fit: BoxFit.contain,
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
  final String inviteCode;

  const SettingsFamilyLinkCard({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SettingsTokens.familyCardHeight,
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: HomeTokens.mainCardGradient,
        borderRadius: BorderRadius.circular(SettingsTokens.cardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: QrImageView(
              data: inviteCode,
              version: QrVersions.auto,
              size: 118,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const SettingsBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          'assets/images/settings/back.svg',
          width: 13,
          height: 25,
        ),
      ),
    );
  }
}
