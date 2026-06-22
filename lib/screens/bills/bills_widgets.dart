import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_widgets.dart';

/// Bills-specific design tokens from Figma node 88:361.
class BillsTokens {
  static const horizontalPadding = HomeTokens.horizontalPadding;
  static const cardRadius = HomeTokens.cardRadius;
  static const summaryHeight = 153.0;
  static const billCardHeight = 128.0;
  static const billTopHeight = 69.0;
  static const billBottomHeight = 59.0;

  static const oweYouGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.6,
    colors: [
      Color(0xB380B2E2),
      Color(0xB37BAABC),
      Color(0xB377A295),
      Color(0xB3729A6F),
      Color(0xB36D9248),
      Color(0xB34B6F59),
      Color(0xB3284B69),
    ],
    stops: [0.0, 0.12, 0.23, 0.35, 0.47, 0.73, 1.0],
  );

  static const billCardGradient = HomeTokens.housemateCardGradient;
}

/// "You owe" / "Owe you" summary tiles from Figma.
class BillsSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool isOweYou;

  const BillsSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.isOweYou = false,
  });

  String get _formattedAmount {
    final rounded = amount == amount.roundToDouble();
    return rounded ? '${amount.round()}\$' : '${amount.toStringAsFixed(1)}\$';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: BillsTokens.summaryHeight,
      decoration: BoxDecoration(
        gradient: isOweYou
            ? BillsTokens.oweYouGradient
            : HomeTokens.mainCardGradient,
        borderRadius: BorderRadius.circular(BillsTokens.cardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formattedAmount,
            style: GoogleFonts.poppins(
              fontSize: 60,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class BillsSectionTitle extends StatelessWidget {
  final String text;

  const BillsSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

/// Category icon from Figma SVG assets.
class BillsCategoryIcon extends StatelessWidget {
  final String category;

  const BillsCategoryIcon({super.key, required this.category});

  String? get _assetPath {
    switch (category.toLowerCase()) {
      case 'shopping':
        return 'assets/images/bills/shopping.svg';
      case 'groceries':
        return 'assets/images/bills/groceries.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assetPath;
    if (asset != null) {
      return SvgPicture.asset(asset, width: 39, height: 39);
    }
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
    );
  }
}

/// Pending bill card matching the Figma two-panel layout.
class BillsPendingCard extends StatelessWidget {
  final String category;
  final double amount;
  final String paidByName;
  final int paidByAvatarIndex;

  const BillsPendingCard({
    super.key,
    required this.category,
    required this.amount,
    required this.paidByName,
    required this.paidByAvatarIndex,
  });

  String get _categoryLabel =>
      category.isEmpty ? 'Other' : _capitalize(category);

  String get _formattedAmount {
    final rounded = amount == amount.roundToDouble();
    return rounded ? '${amount.round()}\$' : '${amount.toStringAsFixed(1)}\$';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: BillsTokens.billCardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BillsTokens.cardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: BillsTokens.billTopHeight,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
            decoration: BoxDecoration(
              gradient: BillsTokens.billCardGradient,
            ),
            child: Row(
              children: [
                BillsCategoryIcon(category: category),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _categoryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  _formattedAmount,
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: BillsTokens.billBottomHeight,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: BillsTokens.billCardGradient,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Paid by',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                HomeCatAvatar(
                  avatarIndex: paidByAvatarIndex,
                  size: 40,
                ),
                const SizedBox(width: 8),
                Text(
                  paidByName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "New bill" pill button from Figma.
class BillsNewBillButton extends StatelessWidget {
  final VoidCallback onTap;

  const BillsNewBillButton({super.key, required this.onTap});

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
              'assets/images/bills/plus_sign.svg',
              width: 31,
              height: 31,
            ),
            const SizedBox(width: 12),
            Text(
              'New bill',
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
