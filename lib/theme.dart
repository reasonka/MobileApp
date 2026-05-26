import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color cardBg = Color(0xFF1A1A2E);
  static const Color surfaceBg = Color(0xFF16213E);

  // Brand / accent
  static const Color pink = Color(0xFFE040FB);
  static const Color pinkLight = Color(0xFFF48FB1);

  // Owe card gradient (purple)
  static const Color oweStart = Color(0xFF6A1B9A);
  static const Color oweEnd = Color(0xFF4A148C);

  // Owed-to-me card gradient (green-teal)
  static const Color owedStart = Color(0xFF1B5E20);
  static const Color owedEnd = Color(0xFF004D40);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);

  // Bottom nav
  static const Color navBg = Color(0xFF12122A);
  static const Color navIconInactive = Color(0xFF616161);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: 'Nunito',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.pink,
          surface: AppColors.cardBg,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
}