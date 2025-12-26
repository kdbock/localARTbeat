import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color accent;
  final bool destructive;

  const SettingsListItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.accent = const Color(0xFF22D3EE),
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: destructive
                          ? Colors.red.withValues(alpha: 0.15)
                          : accent.withValues(alpha: 0.16),
                      border: Border.all(
                        color: destructive
                            ? Colors.red.withValues(alpha: 0.28)
                            : accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: destructive
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.95),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: destructive
                                ? Colors.redAccent
                                : Colors.white.withValues(alpha: 0.92),
                          ),
                        ),

                        if (hasSubtitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
