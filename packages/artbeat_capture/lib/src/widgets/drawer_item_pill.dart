import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_card.dart';

class DrawerItemPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const DrawerItemPill({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF22D3EE);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: selected
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? accent : Colors.white.withValues(alpha: 0.75),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.chevron_right, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
