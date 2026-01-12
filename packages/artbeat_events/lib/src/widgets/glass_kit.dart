import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class WorldBackdrop extends StatelessWidget {
  final List<Color>? colors;
  final Widget? child;

  const WorldBackdrop({super.key, this.colors, this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              colors ??
              const [Color(0xFF05060A), Color(0xFF0B1220), Color(0xFF05060A)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 80,
            left: -20,
            child: _GlowCircle(color: Color(0x407C4DFF)),
          ),
          const Positioned(
            bottom: 40,
            right: -10,
            child: _GlowCircle(color: Color(0x4022D3EE)),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double fillOpacity;
  final Color? borderColor;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 18,
    this.fillOpacity = 0.1,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SafeBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: fillOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: GlassSurface(
          padding: const EdgeInsets.all(10),
          fillOpacity: 0.08,
          child: Icon(icon, color: const Color(0xF2FFFFFF), size: 20),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;

  const _GlowCircle({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
