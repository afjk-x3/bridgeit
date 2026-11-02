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
  static const vehicle = Color(0xFF3A8FDB);
  // The Level 2 bridge.
  static const tower = Color(0xFFD88858);
  static const cable = Color(0xFF183870);
  static const deck = Color(0xFF5B6472);
  static const water = Color(0xFF56B9D6);
  static const rock = Color(0xFF6F7B6A);
  static const correct = Color(0xFF22C55E);
  static const wrong = Color(0xFFDC2626);
  // White surfaces (cards) and text on dark fills.
  static const card = Color(0xFFFFFFFF);
  // Behind a hint or notice with an orange bar.
  static const note = Color(0xFFFFF6EC);
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
  const buttonText = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w800,
    fontSize: 17,
  );
  final rounded14 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  OutlineInputBorder field(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.sky,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.sky,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 72,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.card,
        minimumSize: const Size.fromHeight(56),
        textStyle: buttonText,
        shape: rounded14,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(52),
        textStyle: buttonText,
        side: const BorderSide(color: AppColors.ink, width: 2),
        shape: rounded14,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.ink, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.ink, width: 3),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Nunito',
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: field(AppColors.ink, 2),
      enabledBorder: field(AppColors.ink, 2),
      focusedBorder: field(AppColors.teal, 3),
      errorBorder: field(AppColors.wrong, 2),
      focusedErrorBorder: field(AppColors.wrong, 3),
    ),
  );
}
