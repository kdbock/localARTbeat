// lib/src/widgets/world_background.dart

import 'package:flutter/material.dart';

class WorldBackground extends StatelessWidget {
  final Widget child;
  final bool withBlobs;

  const WorldBackground({
    required this.child,
    this.withBlobs = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        ),
      ),
      child: Stack(
        children: [
          if (withBlobs) const _AnimatedBlobs(),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  radius: 1.2,
                  center: Alignment.center,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AnimatedBlobs extends StatelessWidget {
  const _AnimatedBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _blob(const Offset(150, 200), const Color(0xFF22D3EE), 180),
        _blob(const Offset(300, 400), const Color(0xFFFF3D8D), 160),
        _blob(const Offset(100, 600), const Color(0xFF34D399), 120),
        _blob(const Offset(250, 100), const Color(0xFF7C4DFF), 200),
      ],
    );
  }

  Widget _blob(Offset position, Color color, double size) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.07),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 100,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}
