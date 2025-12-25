import 'package:flutter/material.dart';

/// A progress bar widget for displaying XP progress
class XpProgressBar extends StatelessWidget {
  final double? percent;
  final int? currentXp;
  final int? currentLevel;
  final int? nextLevelXp;

  const XpProgressBar({
    super.key,
    this.percent,
    this.currentXp,
    this.currentLevel,
    this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    double progress;
    if (percent != null) {
      progress = percent!.clamp(0.0, 1.0);
    } else if (currentXp != null &&
        nextLevelXp != null &&
        currentLevel != null) {
      progress = ((currentXp! % 100) / 100.0).clamp(0.0, 1.0);
    } else {
      progress = 0.0;
    }

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.yellow,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
