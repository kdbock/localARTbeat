import 'package:flutter/material.dart';
import 'artbeat_colors.dart';

class ArtbeatTypography {
  // Using Roboto as it's included with Material by default
  static const String _fontFamily = 'Roboto';

  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.5,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
      fontFamily: _fontFamily,
      color: ArtbeatColors.textPrimary,
    ),
  );

  static TextStyle get h1 => textTheme.displayLarge!;
  static TextStyle get h2 => textTheme.displayMedium!;
  static TextStyle get h3 => textTheme.displaySmall!;
  static TextStyle get h4 => textTheme.headlineMedium!;
  static TextStyle get body => textTheme.bodyLarge!;
  static TextStyle get helper => textTheme.bodySmall!;
  static TextStyle get badge => textTheme.labelLarge!;
}
