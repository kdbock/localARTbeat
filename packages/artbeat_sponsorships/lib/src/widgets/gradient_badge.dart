import 'package:flutter/material.dart';

class GradientBadge extends StatelessWidget {
  const GradientBadge({
    super.key,
    required this.child,
    this.size = 40,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF7C4DFF),
            Color(0xFF22D3EE),
          ],
        ),
      ),
      child: Center(child: child),
    );
}
