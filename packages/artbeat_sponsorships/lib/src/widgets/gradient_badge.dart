import 'package:flutter/material.dart';

class GradientBadge extends StatelessWidget {
  const GradientBadge({
    super.key,
    this.child,
    this.label,
    this.icon,
    this.size = 40,
  }) : assert(child != null || label != null || icon != null,
            'Provide a child, label, or icon');

  final Widget? child;
  final String? label;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: Colors.white,
                size: size * 0.5,
              ),
            if (label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );

    return Container(
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
      child: Center(child: content),
    );
  }
}
