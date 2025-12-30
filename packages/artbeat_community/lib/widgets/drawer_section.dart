import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Drawer Section - Section headers for Local ARTbeat drawer
class DrawerSection extends StatelessWidget {
  const DrawerSection({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 8),
    this.fontSize = 12,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 0.8,
    this.textColor,
  });

  final String title;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor ?? Colors.white.withValues(alpha: 0.55),
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}

/// Drawer Divider - Subtle divider for drawer sections
class DrawerDivider extends StatelessWidget {
  const DrawerDivider({
    super.key,
    this.height = 16,
    this.thickness = 1,
    this.indent = 16,
    this.endIndent = 16,
    this.color,
  });

  final double height;
  final double thickness;
  final double indent;
  final double endIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color ?? Colors.white.withValues(alpha: 0.1),
    );
  }
}
