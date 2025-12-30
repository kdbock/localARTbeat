import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gradient Badge - Reusable gradient accent badges and chips
class GradientBadge extends StatelessWidget {
  const GradientBadge({
    super.key,
    required this.text,
    this.icon,
    this.gradient = const LinearGradient(
      colors: [
        Color(0xFF7C4DFF), // Purple
        Color(0xFF22D3EE), // Teal
        Color(0xFF34D399), // Green
      ],
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius = 16,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = 0.5,
  });

  final String text;
  final IconData? icon;
  final Gradient gradient;
  final EdgeInsets padding;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: Colors.white,
              letterSpacing: letterSpacing,
            ),
          ),
        ],
      ),
    );
  }
}

/// Success Badge - Green gradient for positive states
class SuccessBadge extends GradientBadge {
  const SuccessBadge({
    super.key,
    required super.text,
    super.icon,
    super.padding,
    super.borderRadius,
    super.fontSize,
    super.fontWeight,
    super.letterSpacing,
  }) : super(
         gradient: const LinearGradient(
           colors: [
             Color(0xFF34D399), // Green
             Color(0xFF22D3EE), // Teal
           ],
         ),
       );
}

/// Warning Badge - Yellow gradient for attention states
class WarningBadge extends GradientBadge {
  const WarningBadge({
    super.key,
    required super.text,
    super.icon,
    super.padding,
    super.borderRadius,
    super.fontSize,
    super.fontWeight,
    super.letterSpacing,
  }) : super(
         gradient: const LinearGradient(
           colors: [
             Color(0xFFFFC857), // Yellow
             Color(0xFFFF3D8D), // Pink
           ],
         ),
       );
}

/// Error Badge - Red gradient for danger states
class ErrorBadge extends GradientBadge {
  const ErrorBadge({
    super.key,
    required super.text,
    super.icon,
    super.padding,
    super.borderRadius,
    super.fontSize,
    super.fontWeight,
    super.letterSpacing,
  }) : super(
         gradient: const LinearGradient(
           colors: [
             Color(0xFFFF3D8D), // Pink
             Color(0xFF7C4DFF), // Purple
           ],
         ),
       );
}
