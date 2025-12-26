import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsCategoryHeader extends StatelessWidget {
  final String title;

  const SettingsCategoryHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: Colors.white.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}
