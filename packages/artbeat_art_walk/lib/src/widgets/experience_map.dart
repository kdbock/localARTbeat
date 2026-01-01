import 'package:flutter/material.dart';
import 'package:artbeat_core/shared_widgets.dart';

class ExperienceMap extends StatelessWidget {
  final Widget map;
  final Widget hud;
  final VoidCallback onFabPressed;

  const ExperienceMap({
    super.key,
    required this.map,
    required this.hud,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WorldBackground(child: map),
        Positioned(top: 16, right: 16, child: GlassCard(child: hud)),
        Positioned(
          bottom: 24,
          right: 24,
          child: GlassCard(
            borderRadius: 32.0,
            padding: const EdgeInsets.all(12),
            child: IconButton(
              icon: const Icon(Icons.navigation),
              onPressed: onFabPressed,
              iconSize: 28,
              color: Colors.teal,
            ),
          ),
        ),
      ],
    );
  }
}
