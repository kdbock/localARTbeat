// current_step_overlay.dart
import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

class CurrentStepOverlay extends StatelessWidget {
  final String instruction;

  const CurrentStepOverlay({super.key, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        borderRadius: 28.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(instruction, style: AppTextStyles.bodyBold)),
            ],
          ),
        ),
      ),
    );
  }
}
