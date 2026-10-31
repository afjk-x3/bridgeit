import 'package:flutter/material.dart';

/// The only place colors are defined. Brand colors come from the logo.
abstract final class AppColors {
  static const primary = Color(0xFF183870);
  static const accent = Color(0xFFD88858);
  static const piece = Color(0xFFD88858);
  static const teal = Color(0xFF309090);
  static const lightTeal = Color(0xFF80C0A8);
  static const sky = Color(0xFFE6F5FF);
  static const ink = Color(0xFF183870);
  static const bridge = Color(0xFFB45309);
  static const cliff = Color(0xFF15803D);
  static const vehicle = Color(0xFFF59E0B);
  static const correct = Color(0xFF22C55E);
  static const wrong = Color(0xFFDC2626);
  // White surfaces (cards) and text on dark fills.
  static const card = Color(0xFFFFFFFF);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.sky,
    onSurface: AppColors.ink,
    error: AppColors.wrong,
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.sky,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.card,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
