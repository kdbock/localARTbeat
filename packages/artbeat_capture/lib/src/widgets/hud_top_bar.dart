import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

class HudTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;
  final VoidCallback? onBack;

  const HudTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onMenu,
    this.onSearch,
    this.onProfile,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          if (onMenu != null)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onSearch != null)
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, color: Colors.white),
            ),
          if (onProfile != null)
            IconButton(
              onPressed: onProfile,
              icon: const Icon(Icons.person_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
