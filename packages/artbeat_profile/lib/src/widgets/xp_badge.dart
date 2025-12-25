// 📁 lib/artbeat_profile/widgets/xp_badge.dart
import 'package:flutter/material.dart';

class XpBadge extends StatelessWidget {
  final int xp;

  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'XP: $xp',
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}
