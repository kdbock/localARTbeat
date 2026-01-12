import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/safe_backdrop_filter.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double? borderRadius;
  final double blur;
  final Color? fillColor;
  final Color? glassColor;
  final Color? borderColor;
  final BoxShadow? shadow;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double? glassOpacity;
  final double? borderOpacity;
  final bool showAccentGlow;
  final Color? accentColor;
  final Color? glassBackground;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 24,
    this.borderRadius,
    this.blur = 16,
    this.fillColor,
    this.glassColor,
    this.borderColor,
    this.shadow,
    this.shadows,
    this.onTap,
    this.glassOpacity,
    this.borderOpacity,
    this.showAccentGlow = false,
    this.accentColor,
    this.glassBackground,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? radius;
    final borderRadiusGeometry = BorderRadius.circular(effectiveRadius);
    final effectiveGlassColor = glassBackground ??
        fillColor ??
        glassColor ??
        Colors.white.withValues(alpha: glassOpacity ?? 0.06);
    final effectiveBorderColor = borderColor ??
        Colors.white.withValues(alpha: borderOpacity ?? 0.12);
    final shadowList =
        shadows ?? (shadow != null ? <BoxShadow>[shadow!] : null);

    final cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveGlassColor,
        borderRadius: borderRadiusGeometry,
        border: Border.all(
          color: effectiveBorderColor,
        ),
        boxShadow: shadowList ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
              if (showAccentGlow)
                BoxShadow(
                  color: (accentColor ?? const Color(0xFF00FD8A))
                      .withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
            ],
      ),
      child: child,
    );

    Widget content = ClipRRect(
      borderRadius: borderRadiusGeometry,
      child: SafeBackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: cardBody,
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadiusGeometry,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: content,
    );
  }
}
