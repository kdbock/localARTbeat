import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../user_experience_card.dart';
import '../achievement_badge.dart';

class DashboardUserSection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardUserSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = viewModel.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: UserExperienceCard(
        user: currentUser,
        achievements: _convertAchievements(viewModel.achievements),
        onTap: () => _handleUserAction(context, 'profile'),
        onProfileTap: () => _handleUserAction(context, 'profile'),
        onAchievementsTap: () => _handleUserAction(context, 'achievements'),
      ),
    );
  }

  List<AchievementBadgeData> _convertAchievements(
    List<AchievementModel> achievements,
  ) {
    return achievements
        .map(
          (achievement) => AchievementBadgeData(
            title: achievement.title,
            description: achievement.description,
            icon: _getIconFromString(achievement.iconName),
            isUnlocked:
                true, // All achievements in this list are already earned
            progress: 1.0, // Fully completed since they're earned achievements
          ),
        )
        .toList();
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'explore':
        return Icons.explore;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'collections':
        return Icons.collections;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'add_a_photo':
        return Icons.add_a_photo;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'palette':
        return Icons.palette;
      case 'star':
        return Icons.star;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'access_time':
        return Icons.access_time;
      default:
        return Icons.emoji_events;
    }
  }

  void _handleUserAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'captures':
        Navigator.pushNamed(context, '/captures');
        break;
      case 'following':
        Navigator.pushNamed(context, '/following');
        break;
      case 'achievements':
        Navigator.pushNamed(context, '/achievements');
        break;
      default:
        // Handle unknown actions
        break;
    }
  }
}
