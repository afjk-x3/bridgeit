import 'package:flutter/material.dart';

/// The only place colors are defined. Placeholder palette until the client
/// sends their final logo; swap the values here and nothing else changes.
abstract final class AppColors {
  static const primary = Color(0xFF0E7490);
  static const accent = Color(0xFFEC4899);
  static const piece = Color(0xFF9D174D);
  static const sky = Color(0xFFE0F2FE);
  static const ink = Color(0xFF1E293B);
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
    // The wordmark style; AbrilFatface has no bold, so never add fontWeight to it.
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontFamily: 'AbrilFatface'),
    ),
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
