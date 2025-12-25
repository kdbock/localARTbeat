import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_card.dart';

class HudTopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const HudTopBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      glassColor: Colors.white.withValues(alpha: 0.15),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
