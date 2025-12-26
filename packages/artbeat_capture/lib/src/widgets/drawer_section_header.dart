import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DrawerSectionHeader extends StatelessWidget {
  final String title;

  const DrawerSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.55),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
