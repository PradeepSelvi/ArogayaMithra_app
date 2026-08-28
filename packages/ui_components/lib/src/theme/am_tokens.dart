import 'package:flutter/material.dart';

/// Design tokens.
///
/// Colours are chosen for contrast against white and near-white surfaces at
/// WCAG AA for body text. Status colour is always paired with an icon and a
/// label in the widgets, so the meaning survives colour blindness and a washed
/// out screen in daylight.
abstract final class AmTokens {
  // ----- Brand -------------------------------------------------------------

  /// Deep teal. Reads as clinical rather than commercial.
  static const primary = Color(0xFF0F6E63);
  static const primaryDark = Color(0xFF0A4F47);
  static const primaryLight = Color(0xFFE0F2F0);

  static const secondary = Color(0xFF1B4B8F);
  static const secondaryLight = Color(0xFFE5EDF8);

  // ----- Semantic ----------------------------------------------------------

  /// Emergency. Reserved exclusively for the emergency pathway so it never
  /// competes for attention (PRD 16: urgent action must be distinguishable from
  /// general information).
  static const emergency = Color(0xFFB3261E);
  static const emergencyLight = Color(0xFFFCEEEE);

  static const warning = Color(0xFF8A5300);
  static const warningLight = Color(0xFFFFF3E0);

  static const success = Color(0xFF1B6B31);
  static const successLight = Color(0xFFE7F4EA);

  static const info = Color(0xFF1B4B8F);
  static const infoLight = Color(0xFFE5EDF8);

  /// Unknown or stale data. Deliberately grey, never green.
  static const unknown = Color(0xFF5A5F66);
  static const unknownLight = Color(0xFFF0F1F2);

  // ----- Neutrals ----------------------------------------------------------

  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF6F7F8);
  static const border = Color(0xFFD6D9DC);
  static const textPrimary = Color(0xFF16191C);
  static const textSecondary = Color(0xFF4A4F55);

  // ----- Metrics -----------------------------------------------------------

  /// Minimum interactive size. Above the 48dp guideline because the target user
  /// may be older, outdoors, or using the phone one-handed.
  static const minTouchTarget = 56.0;

  /// Primary actions in the citizen app are larger still.
  static const largeTouchTarget = 72.0;

  static const radiusSmall = 8.0;
  static const radiusMedium = 14.0;
  static const radiusLarge = 20.0;

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;

  /// Widest comfortable reading measure for the web consoles.
  static const maxContentWidth = 1100.0;
}
