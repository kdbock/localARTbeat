// lib/src/widgets/typography.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle screenTitle([Color color = Colors.white]) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle sectionLabel([Color color = Colors.white]) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle body([Color color = Colors.white]) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle helper([Color color = Colors.white70]) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color.withValues(
          red: ((color.r * 255.0).round().clamp(0, 255)).toDouble(),
          green: ((color.g * 255.0).round().clamp(0, 255)).toDouble(),
          blue: ((color.b * 255.0).round().clamp(0, 255)).toDouble(),
          alpha: ((0.6 * 255).round()).toDouble(),
        ),
      );

  static TextStyle badge([Color color = Colors.white]) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
