import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_card.dart';

class HudTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool glassBackground;
  final double height;

  const HudTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBackPressed,
    this.showBackButton = true,
    this.glassBackground = true,
    this.height = 74,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...actions else const SizedBox(width: 48),
        ],
      ),
    );

    if (!glassBackground) {
      return Container(
        color: Colors.transparent,
        alignment: Alignment.centerLeft,
        child: content,
      );
    }

    return GlassCard(
      glassColor: Colors.white.withValues(alpha: 0.15),
      margin: EdgeInsets.zero,
      child: content,
    );
  }
}
