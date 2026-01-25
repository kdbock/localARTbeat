import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Drawer Item Pill - Navigation items for Local ARTbeat drawer
class DrawerItemPill extends StatelessWidget {
  const DrawerItemPill({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.badgeText,
    this.height = 48,
    this.borderRadius = 20,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final String? badgeText;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Icon chip
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF22D3EE).withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? const Color(0xFF22D3EE)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Badge (optional)
                if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D3EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawer Item Pill with Gradient - Enhanced version with gradient accent
class DrawerItemPillGradient extends DrawerItemPill {
  const DrawerItemPillGradient({
    super.key,
    required super.title,
    required super.icon,
    required super.onTap,
    super.isSelected = false,
    super.badgeText,
    super.height = 48,
    super.borderRadius = 20,
    super.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(borderRadius),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
            ),
            child: Row(
              children: [
                // Icon chip
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Badge (optional)
                if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
