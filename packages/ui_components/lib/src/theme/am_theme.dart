import 'package:flutter/material.dart';

import 'am_tokens.dart';

/// Theme for every ArogyaMitra surface.
abstract final class AmTheme {
  /// Citizen and field apps: larger type and taller controls.
  static ThemeData mobile() => _base(scale: 1.0, density: 0.0);

  /// Web consoles: denser, because staff scan tables rather than read prose.
  static ThemeData console() => _base(scale: 0.92, density: -1.0);

  static ThemeData _base({required double scale, required double density}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AmTokens.primary,
      brightness: Brightness.light,
      primary: AmTokens.primary,
      secondary: AmTokens.secondary,
      error: AmTokens.emergency,
      surface: AmTokens.surface,
    );

    final textTheme = _textTheme(scale);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AmTokens.surfaceMuted,
      visualDensity: VisualDensity(horizontal: density, vertical: density),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AmTokens.surface,
        foregroundColor: AmTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AmTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          side: const BorderSide(color: AmTokens.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AmTokens.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AmTokens.spaceLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AmTokens.minTouchTarget),
          side: const BorderSide(color: AmTokens.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AmTokens.minTouchTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AmTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AmTokens.spaceMd,
          vertical: AmTokens.spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          borderSide: const BorderSide(color: AmTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          borderSide: const BorderSide(color: AmTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
          borderSide: const BorderSide(color: AmTokens.primary, width: 2),
        ),
        labelStyle: textTheme.bodyLarge,
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AmTokens.spaceMd,
          vertical: AmTokens.spaceSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmTokens.radiusSmall),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: AmTokens.spaceMd,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AmTokens.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AmTokens.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AmTokens.textPrimary,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmTokens.radiusMedium),
        ),
      ),
    );
  }

  /// Type scale. Body text starts at 17sp rather than 14sp: the platform is used
  /// by people who may not read comfortably, so the default must be generous
  /// even before the OS text-scaling setting is applied.
  static TextTheme _textTheme(double scale) => TextTheme(
        displaySmall: TextStyle(
          fontSize: 34 * scale,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AmTokens.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28 * scale,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: AmTokens.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 23 * scale,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AmTokens.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AmTokens.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AmTokens.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 17 * scale,
          height: 1.45,
          color: AmTokens.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15 * scale,
          height: 1.45,
          color: AmTokens.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 13 * scale,
          height: 1.4,
          color: AmTokens.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 17 * scale,
          fontWeight: FontWeight.w600,
          color: AmTokens.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w600,
          color: AmTokens.textSecondary,
        ),
      );
}
