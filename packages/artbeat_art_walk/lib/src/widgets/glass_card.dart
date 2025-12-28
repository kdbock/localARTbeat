// lib/src/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? fillColor;
  final double blur;
  final BoxShadow? shadow;

  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.fillColor,
    this.blur = 18.0,
    this.shadow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                fillColor ??
                const Color(0xFF000000).withValues(
                  red: 0.0,
                  green: 0.0,
                  blue: 0.0,
                  alpha: (0.3 * 255),
                ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(
                red: 255.0,
                green: 255.0,
                blue: 255.0,
                alpha: (0.12 * 255),
              ),
              width: 1.0,
            ),
            boxShadow: shadow != null ? [shadow!] : [],
          ),
          child: child,
        ),
      ),
    );
  }
}
