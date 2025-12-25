import 'dart:math' as math;
import 'package:flutter/material.dart';

class WorldBackground extends StatefulWidget {
  final Widget child;
  final bool animated;

  const WorldBackground({super.key, required this.child, this.animated = true});

  @override
  State<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends State<WorldBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.animated) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF07060F),
                Color(0xFF0A1330),
                Color(0xFF071C18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        if (widget.animated)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _WorldBlobsPainter(_animationController.value),
                size: Size.infinite,
              );
            },
          ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _WorldBlobsPainter extends CustomPainter {
  final double t;

  _WorldBlobsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBlob(
      canvas,
      size,
      const Color(0xFF22D3EE),
      0.18,
      0.20,
      0.36,
      phase: 0.0,
    );
    _drawBlob(
      canvas,
      size,
      const Color(0xFF7C4DFF),
      0.84,
      0.22,
      0.30,
      phase: 0.2,
    );
    _drawBlob(
      canvas,
      size,
      const Color(0xFFFF3D8D),
      0.78,
      0.76,
      0.42,
      phase: 0.45,
    );
    _drawBlob(
      canvas,
      size,
      const Color(0xFF34D399),
      0.16,
      0.78,
      0.34,
      phase: 0.62,
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    Color color,
    double ax,
    double ay,
    double r, {
    required double phase,
  }) {
    final dx = 0.03 * math.sin((t + phase) * 2 * math.pi);
    final dy = 0.03 * math.cos((t + phase) * 2 * math.pi);

    final center = Offset(size.width * (ax + dx), size.height * (ay + dy));
    final radius = size.width * r;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _WorldBlobsPainter oldDelegate) =>
      oldDelegate.t != t;
}
