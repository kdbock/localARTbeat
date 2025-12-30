import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass Card / Panel - The signature Local ARTbeat glass container
/// Features backdrop blur, subtle white fill, and accent borders
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.glassOpacity = 0.08,
    this.borderOpacity = 0.12,
    this.blurSigma = 16,
    this.showAccentGlow = false,
    this.accentColor = const Color(0xFF22D3EE),
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double glassOpacity;
  final double borderOpacity;
  final double blurSigma;
  final bool showAccentGlow;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: glassOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
                width: 1,
              ),
              boxShadow: showAccentGlow
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.1),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass Panel - Alternative naming for larger glass containers
class GlassPanel extends GlassCard {
  const GlassPanel({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(20),
    super.margin,
    super.borderRadius = 28,
    super.glassOpacity = 0.06,
    super.borderOpacity = 0.10,
    super.blurSigma = 20,
    super.showAccentGlow,
    super.accentColor,
  });
}
