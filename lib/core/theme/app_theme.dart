import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: isLight ? KsmsColors.navy700 : KsmsColors.teal400,
      brightness: brightness,
    ).copyWith(
      primary: isLight ? KsmsColors.navy700 : KsmsColors.teal400,
      secondary: KsmsColors.teal500,
      surface: isLight ? Colors.white : KsmsColors.navy900,
      error: KsmsColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: KsmsTypography.textTheme.apply(
        bodyColor: isLight ? KsmsColors.navy900 : Colors.white,
        displayColor: isLight ? KsmsColors.navy900 : Colors.white,
      ),
      scaffoldBackgroundColor: isLight ? KsmsColors.navy50 : KsmsColors.navy900,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? Colors.white : KsmsColors.navy800,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: isLight ? KsmsColors.navy800 : Colors.white),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isLight ? KsmsColors.navy900 : Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? Colors.white : KsmsColors.navy800,
        shape: RoundedRectangleBorder(
          borderRadius: KsmsRadii.md,
          side: BorderSide(color: isLight ? const Color(0xFFE3EBF3) : KsmsColors.navy700),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : KsmsColors.navy800,
        border: OutlineInputBorder(
          borderRadius: KsmsRadii.sm,
          borderSide: BorderSide(color: isLight ? const Color(0xFFD8E2EC) : KsmsColors.navy600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KsmsRadii.sm,
          borderSide: BorderSide(color: isLight ? const Color(0xFFD8E2EC) : KsmsColors.navy600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KsmsRadii.sm,
          borderSide: const BorderSide(color: KsmsColors.teal500, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KsmsColors.navy700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: KsmsRadii.sm),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? KsmsColors.navy700 : KsmsColors.teal400,
          side: BorderSide(color: isLight ? KsmsColors.navy700 : KsmsColors.teal400),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: KsmsRadii.sm),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: KsmsRadii.sm)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? KsmsColors.navy100 : KsmsColors.navy700,
        labelStyle: TextStyle(fontSize: 12, color: isLight ? KsmsColors.navy800 : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: KsmsRadii.sm),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isLight ? KsmsColors.navy800 : KsmsColors.navy900,
        selectedIconTheme: const IconThemeData(color: KsmsColors.teal400),
        selectedLabelTextStyle: const TextStyle(color: KsmsColors.teal400, fontWeight: FontWeight.w600),
        unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.7)),
        unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? const Color(0xFFE3EBF3) : KsmsColors.navy700,
        thickness: 1,
      ),
    );
    return base;
  }
}
