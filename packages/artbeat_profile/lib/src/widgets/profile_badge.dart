// 📁 lib/artbeat_profile/widgets/profile_badge.dart
import 'package:flutter/material.dart';

class ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const ProfileBadge({
    super.key,
    required this.icon,
    required this.label,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
