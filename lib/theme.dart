import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/theme_service.dart';

/// Height of the persistent global top bar (does not include the system status bar).
const double kGlobalTopBarHeight = 64.0;

/// Semantic palette — switches with [ThemeService.resolvedBrightness].
class HomiePalette {
  final Color scaffoldBg;
  final Color screenBg;
  final Color cardBg;
  final Color surfaceBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color navBarFill;
  final Color navBarBorder;
  final Color navActivePill;
  final Color navActivePillBorder;
  final Color glassButtonFill;
  final Color topBarBg;
  final Color divider;
  final Color dialogBg;
  final Color fieldFill;
  final bool useDarkTopPanelImage;
  final RadialGradient panelGradient;
  final RadialGradient mainChoreGradient;
  final RadialGradient memberPanelGradient;
  final RadialGradient fieldGradient;
  final LinearGradient topBarGradient;
  final List<Color> bottomFadeColors;
  final List<double> bottomFadeStops;
  final Color pillBg;
  final Color cardBorder;
  final BoxShadow cardShadow;
  final RadialGradient leaderboardListGradient;

  const HomiePalette({
    required this.scaffoldBg,
    required this.screenBg,
    required this.cardBg,
    required this.surfaceBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.navBarFill,
    required this.navBarBorder,
    required this.navActivePill,
    required this.navActivePillBorder,
    required this.glassButtonFill,
    required this.topBarBg,
    required this.divider,
    required this.dialogBg,
    required this.fieldFill,
    required this.useDarkTopPanelImage,
    required this.panelGradient,
    required this.mainChoreGradient,
    required this.memberPanelGradient,
    required this.fieldGradient,
    required this.topBarGradient,
    required this.bottomFadeColors,
    required this.bottomFadeStops,
    required this.pillBg,
    required this.cardBorder,
    required this.cardShadow,
    required this.leaderboardListGradient,
  });

  static HomiePalette get current =>
      ThemeService.instance.isLight ? light : dark;

  static const dark = HomiePalette(
    scaffoldBg: Color(0xFF0D0D1A),
    screenBg: Color(0xFF161823),
    cardBg: Color(0xFF1A1A2E),
    surfaceBg: Color(0xFF16213E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0BEC5),
    textMuted: Color(0xFF607D8B),
    navBarFill: Color(0x6B161823),
    navBarBorder: Color(0x29FFFFFF),
    navActivePill: Color(0x2EE040FB),
    navActivePillBorder: Color(0x59E040FB),
    glassButtonFill: Color(0x33252B4C),
    topBarBg: Color(0xFF161823),
    divider: Color(0xFF2A2A3E),
    dialogBg: Color(0xFF1A1A2E),
    fieldFill: Color(0xFF0D0D1A),
    useDarkTopPanelImage: true,
    panelGradient: RadialGradient(
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
    ),
    mainChoreGradient: RadialGradient(
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
    ),
    memberPanelGradient: RadialGradient(
      center: Alignment(0.86, 0.62),
      radius: 1.4,
      colors: [
        Color(0x33AF69F1),
        Color(0x33DA70D7),
        Color(0x33AE67BC),
        Color(0x33815EA0),
        Color(0x33555485),
      ],
      stops: [0.0, 0.47, 0.60, 0.80, 1.0],
    ),
    fieldGradient: RadialGradient(
      center: Alignment(0.86, 0.62),
      radius: 1.6,
      colors: [
        Color(0x80AF69F1),
        Color(0x80DA70D7),
        Color(0x80AE67BC),
        Color(0x80815EA0),
        Color(0x80555485),
        Color(0x803E5077),
        Color(0x80284B69),
      ],
      stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
    ),
    topBarGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF161823), Color(0xFF161823)],
    ),
    bottomFadeColors: [
      Colors.transparent,
      Color(0x59000000),
      Color(0xAD000000),
      Color(0xE0000000),
      Color(0xF2000000),
    ],
    bottomFadeStops: [0.0, 0.3, 0.55, 0.8, 1.0],
    pillBg: Color(0xFF23233A),
    cardBorder: Color(0xFF2E2E50),
    cardShadow: BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 4),
      blurRadius: 4,
    ),
    leaderboardListGradient: RadialGradient(
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
    ),
  );

  /// Light mode hierarchy:
  /// - Quiet neutral stage (bg)
  /// - White secondary cards (chores, members, settings rows)
  /// - Saturated hero panels (leaderboard, Family Link) with white text
  static const light = HomiePalette(
    scaffoldBg: Color(0xFFF0EFF4),
    screenBg: Color(0xFFF0EFF4),
    cardBg: Color(0xFFFFFFFF),
    surfaceBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF3D3558),
    textSecondary: Color(0xFF6F6788),
    textMuted: Color(0xFF9A93AE),
    navBarFill: Color(0xF7FFFFFF),
    navBarBorder: Color(0x33A89FBA),
    navActivePill: Color(0x2EE040FB),
    navActivePillBorder: Color(0x66E040FB),
    // White glass CTA — pops on neutral stage.
    glassButtonFill: Color(0xF2FFFFFF),
    topBarBg: Color(0xFFF0EFF4),
    divider: Color(0xFFE4E0EC),
    dialogBg: Color(0xFFFFFFFF),
    fieldFill: Color(0xFFF7F6FA),
    useDarkTopPanelImage: false,
    // Secondary panels: crisp white (not purple wash).
    panelGradient: RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    ),
    mainChoreGradient: RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    ),
    memberPanelGradient: RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    ),
    fieldGradient: RadialGradient(
      center: Alignment(0.86, 0.62),
      radius: 1.6,
      colors: [
        Color(0xFFE8DCF6),
        Color(0xFFF0E8FA),
        Color(0xFFF7F4FC),
        Color(0xFFFFFFFF),
        Color(0xFFFFFFFF),
        Color(0xFFFFFFFF),
        Color(0xFFFFFFFF),
      ],
      stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
    ),
    topBarGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF0EFF4), Color(0xFFF0EFF4)],
    ),
    bottomFadeColors: [
      Colors.transparent,
      Color(0x00F0EFF4),
      Color(0x99F0EFF4),
      Color(0xD9F0EFF4),
      Color(0xFFF0EFF4),
    ],
    bottomFadeStops: [0.0, 0.3, 0.55, 0.8, 1.0],
    pillBg: Color(0xFFF0EDF6),
    cardBorder: Color(0xFFDCD7E8),
    cardShadow: BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
    // Hero: saturated purple→blue (Figma leaderboard energy).
    leaderboardListGradient: RadialGradient(
      center: Alignment(0.86, 0.62),
      radius: 1.6,
      colors: [
        Color(0xFFB86FE0),
        Color(0xFFC47AE8),
        Color(0xFFB888E8),
        Color(0xFFA090E0),
        Color(0xFF8898E0),
        Color(0xFF70A8E0),
        Color(0xFF58B8DC),
        Color(0xFF48C0D8),
        Color(0xFF40C4D4),
      ],
      stops: [0.0, 0.47, 0.60, 0.73, 0.80, 0.87, 0.93, 0.97, 1.0],
    ),
  );

  /// Hero CTA gradient (Family Link, featured cards) — light mode only.
  static const lightHeroGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.8,
    colors: [
      Color(0xFFC47AE8),
      Color(0xFFB888E8),
      Color(0xFFA090E0),
      Color(0xFF8898E0),
      Color(0xFF70A8E0),
      Color(0xFF58B8DC),
      Color(0xFF48C0D8),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
  );
}

class AppColors {
  static const Color pink = Color(0xFFE040FB);
  static const Color pinkLight = Color(0xFFF48FB1);

  static const Color oweStart = Color(0xFF6A1B9A);
  static const Color oweEnd = Color(0xFF4A148C);
  static const Color owedStart = Color(0xFF1B5E20);
  static const Color owedEnd = Color(0xFF004D40);

  /// Figma bills summary panels (node 88:361) — dark art, light pastel variation.
  /// Direction matches Figma: bottom-left → top-right.
  static LinearGradient get youOweGradient => ThemeService.instance.isLight
      ? const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFB888E0),
            Color(0xFFD078D8),
            Color(0xFFE868C8),
          ],
        )
      : const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [oweEnd, oweStart, Color(0xFF9C27B0)],
        );

  static LinearGradient get oweYouGradient => ThemeService.instance.isLight
      ? const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF48B8A8),
            Color(0xFF60C888),
            Color(0xFF88D858),
          ],
        )
      : const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [owedEnd, owedStart, Color(0xFF66BB6A)],
        );

  /// Text on colored hero panels (leaderboard, balance, Family Link).
  static const Color onHero = Color(0xFFFFFFFF);
  static Color get onHeroSecondary =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.8);

  /// Text on balance summary panels (always on saturated color).
  static Color get onBalancePanel => onHero;
  static Color get onBalancePanelSecondary => onHeroSecondary;

  /// Elevated shadow for hero cards in light mode.
  static List<BoxShadow> get heroShadow => ThemeService.instance.isLight
      ? const [
          BoxShadow(
            color: Color(0x339B6AD4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ]
      : [HomiePalette.current.cardShadow];

  /// Secondary white cards in light mode (border + soft lift).
  static BoxDecoration secondaryCard({double radius = 20}) {
    final p = HomiePalette.current;
    if (ThemeService.instance.isLight) {
      return BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.cardBorder),
        boxShadow: [p.cardShadow],
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [p.cardShadow],
    );
  }

  static Color get darkBg => HomiePalette.current.scaffoldBg;
  static Color get cardBg => HomiePalette.current.cardBg;
  static Color get surfaceBg => HomiePalette.current.surfaceBg;
  static Color get textPrimary => HomiePalette.current.textPrimary;
  static Color get textSecondary => HomiePalette.current.textSecondary;
  static Color get textMuted => HomiePalette.current.textMuted;

  /// Text/icons on gradient panels & glass cards (follows theme).
  static Color get onPanel => textPrimary;
  static Color get onPanelSecondary => textSecondary;
  static Color get onPanelMuted => textMuted;
  static Color get onPanelDivider => HomiePalette.current.divider;

  /// Plus / add icons on glass "New ___" buttons.
  /// White in dark mode (on dark glass); pink in light mode (on lilac glass).
  static Color get onGlassIcon =>
      ThemeService.instance.isLight ? pink : const Color(0xFFFFFFFF);

  /// Text on always-dark accent art (owe cards, pink CTAs).
  static const Color onAccent = Color(0xFFFFFFFF);
  static Color get onAccentSecondary =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.72);
}

/// Shared panel decoration: light solid cards in light mode, dark PNG in dark mode.
class HomiePanel {
  static BoxDecoration imageOrCard({
    required String darkAsset,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.fill,
  }) {
    final p = HomiePalette.current;
    if (ThemeService.instance.isLight) {
      return BoxDecoration(
        color: p.cardBg,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
        boxShadow: [p.cardShadow],
      );
    }
    return BoxDecoration(
      borderRadius: borderRadius,
      image: DecorationImage(
        image: AssetImage(darkAsset),
        fit: fit,
      ),
    );
  }

  static BoxDecoration card({
    BorderRadius? borderRadius,
    Gradient? gradient,
  }) {
    final p = HomiePalette.current;
    return BoxDecoration(
      color: gradient == null ? p.cardBg : null,
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: gradient == null ? Border.all(color: p.cardBorder) : null,
      boxShadow: [p.cardShadow],
    );
  }
}

/// Fills a [Stack] slot: dark PNG in dark mode, solid card color in light mode.
class HomiePanelFill extends StatelessWidget {
  final String darkAsset;
  final BoxFit fit;

  const HomiePanelFill({
    super.key,
    required this.darkAsset,
    this.fit = BoxFit.fill,
  });

  @override
  Widget build(BuildContext context) {
    if (ThemeService.instance.isLight) {
      return ColoredBox(color: HomiePalette.current.cardBg);
    }
    return Image.asset(darkAsset, fit: fit);
  }
}

class AppTheme {
  static ThemeData _base(Brightness brightness) {
    final p = brightness == Brightness.light
        ? HomiePalette.light
        : HomiePalette.dark;

    final baseText = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: p.textPrimary,
        letterSpacing: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: p.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: p.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: p.scaffoldBg,
      textTheme: GoogleFonts.poppinsTextTheme(baseText),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pink,
        brightness: brightness,
        surface: p.cardBg,
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.dialogBg),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.cardBg,
        contentTextStyle: GoogleFonts.poppins(color: p.textPrimary),
      ),
    );
  }

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);
}
