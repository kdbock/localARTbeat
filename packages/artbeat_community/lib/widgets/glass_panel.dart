import 'package:flutter/material.dart';
import 'package:artbeat_core/shared_widgets.dart';

/// Lightweight wrapper to preserve older GlassPanel API after widget cleanup.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      margin: margin,
      radius: radius,
      child: child,
    );
  }
}
