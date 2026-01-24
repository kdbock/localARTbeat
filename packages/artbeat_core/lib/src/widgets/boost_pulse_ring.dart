import 'dart:math' as math;

import 'package:flutter/material.dart';

class BoostPulseRing extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double ringWidth;
  final double ringPadding;
  final Duration duration;
  final List<Color> colors;

  const BoostPulseRing({
    super.key,
    required this.child,
    this.enabled = true,
    this.ringWidth = 2.0,
    this.ringPadding = 4.0,
    this.duration = const Duration(milliseconds: 1400),
    this.colors = const [Color(0xFFF97316), Color(0xFF22D3EE)],
  });

  @override
  State<BoostPulseRing> createState() => _BoostPulseRingState();
}

class _BoostPulseRingState extends State<BoostPulseRing>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant BoostPulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && _controller == null) {
      _startAnimation();
    } else if (!widget.enabled && _controller != null) {
      _controller?.dispose();
      _controller = null;
    }
  }

  void _startAnimation() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;

    if (!widget.enabled || _controller == null || reduceMotion) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _PulseRingPainter(
            progress: _controller!.value,
            ringWidth: widget.ringWidth,
            ringPadding: widget.ringPadding,
            colors: widget.colors,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double progress;
  final double ringWidth;
  final double ringPadding;
  final List<Color> colors;

  _PulseRingPainter({
    required this.progress,
    required this.ringWidth,
    required this.ringPadding,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius =
        (math.min(size.width, size.height) / 2) - ringWidth - ringPadding;
    if (baseRadius <= 0) return;

    _drawRing(canvas, center, baseRadius, progress);
    _drawRing(canvas, center, baseRadius, (progress + 0.55) % 1.0);
  }

  void _drawRing(Canvas canvas, Offset center, double baseRadius, double t) {
    final scale = 0.85 + (0.25 * t);
    final radius = baseRadius * scale;
    final opacity = (1 - t).clamp(0.0, 1.0) * 0.55;
    if (opacity <= 0) return;

    final ringColors =
        colors.map((color) => color.withValues(alpha: opacity)).toList();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..shader = SweepGradient(
        colors: ringColors.length < 2
            ? [ringColors.first, ringColors.first]
            : ringColors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.ringPadding != ringPadding ||
        oldDelegate.colors != colors;
  }
}
