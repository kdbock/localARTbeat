import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementCategoryTile extends StatelessWidget {
  final String category;

  const AchievementCategoryTile({super.key, required this.category});

  IconData get _categoryIcon {
    switch (category) {
      case 'First Achievements':
        return Icons.flag;
      case 'Milestone Achievements':
        return Icons.emoji_events;
      case 'Creator Achievements':
        return Icons.create;
      case 'Explorer Achievements':
        return Icons.explore;
      case 'Quest Achievements':
        return Icons.assignment;
      case 'Streak Achievements':
        return Icons.local_fire_department;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1),
      ),
      child: Row(
        children: [
          Icon(_categoryIcon, color: const Color(0xFF7C4DFF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xE6FFFFFF),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0x80FFFFFF), size: 20),
        ],
      ),
    );
  }
}
