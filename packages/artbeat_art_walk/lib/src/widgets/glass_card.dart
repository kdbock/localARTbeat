// lib/src/widgets/glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? radius;
  final Color? fillColor;
  final double blur;
  final BoxShadow? shadow;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.radius,
    this.fillColor,
    this.blur = 18.0,
    this.shadow,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? borderRadius;
    final borderRadiusGeometry = BorderRadius.circular(effectiveRadius);
    Widget card = ClipRRect(
      borderRadius: borderRadiusGeometry,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor ??
                const Color(0xFF000000).withValues(
                  red: 0.0,
                  green: 0.0,
                  blue: 0.0,
                  alpha: (0.3 * 255),
                ),
            borderRadius: borderRadiusGeometry,
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(
                red: 255.0,
                green: 255.0,
                blue: 255.0,
                alpha: (0.12 * 255),
              ),
              width: 1.0,
            ),
            boxShadow: shadows ?? (shadow != null ? [shadow!] : []),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadiusGeometry,
          child: card,
        ),
      );
    }

    return Container(
      margin: margin,
      child: card,
    );
  }
}
