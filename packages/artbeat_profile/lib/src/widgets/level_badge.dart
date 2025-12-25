import 'package:flutter/material.dart';

/// Dummy widget for LevelBadge
class LevelBadge extends StatelessWidget {
  final dynamic level;

  const LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Text('Level $level');
  }
}
