import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerkItem extends StatelessWidget {
  final String perk;

  const PerkItem({super.key, required this.perk});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star, size: 16, color: Color(0xFF7C4DFF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            perk,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ),
      ],
    );
  }
}
