import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'glass_card.dart';
export 'gradient_cta_button.dart';
export 'hud_top_bar.dart';
export 'world_background.dart';

/// Centralized text styles using GoogleFonts.spaceGrotesk
/// Apply consistent typography across the app following design guide
class AppTextStyles {
  static TextStyle get sectionTitle => GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle get statValue => GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle get statLabel => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static TextStyle get cardCaptionWhite => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static TextStyle get cardTitleWhite => GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get cardSubtitleWhite => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static TextStyle get bodyBold => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static TextStyle get bodySmall => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
  );
  static TextStyle get heading1 => GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle get heading2 => GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle get body => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  static TextStyle get small => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  static TextStyle get label => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static TextStyle get whiteHeading => GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get whiteBody => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static TextStyle get whiteSmall => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  static TextStyle get accent => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF6C63FF),
  );
}
