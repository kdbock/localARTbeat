// 📁 lib/artbeat_profile/widgets/section_header.dart
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final IconData? icon;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.icon,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          if (trailing != null) 
            trailing!
          else if (onViewAll != null)
            TextButton(onPressed: onViewAll, child: const Text('View All')),
        ],
      ),
    );
  }
}
