import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/artbeat_colors.dart';

/// A themed achievement badge widget to display individual achievements
class AchievementBadge extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0 for partially completed achievements
  final Color? customColor;
  final VoidCallback? onTap;
  final bool showProgress;
  final String? progressText;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.progress = 0.0,
    this.customColor,
    this.onTap,
    this.showProgress = false,
    this.progressText,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.customColor ?? ArtbeatColors.primaryPurple;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 120,
                height: 150,
                margin: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 2,
                  bottom: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isUnlocked ? color : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isUnlocked
                          ? color.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Achievement Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.isUnlocked
                              ? LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey[300]!,
                                    Colors.grey[400]!,
                                  ],
                                ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isUnlocked
                              ? Colors.white
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Achievement Title
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.isUnlocked
                                  ? ArtbeatColors.textPrimary
                                  : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Achievement Description
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 9,
                              color: widget.isUnlocked
                                  ? ArtbeatColors.textSecondary
                                  : Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Progress indicator for partial achievements
                      if (widget.showProgress && !widget.isUnlocked) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 70,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: widget.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        if (widget.progressText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.progressText!,
                            style: TextStyle(
                              fontSize: 7,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],

                      // Unlocked indicator
                      if (widget.isUnlocked) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'achievement_badge_unlocked',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ).tr(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A horizontal scrollable list of achievement badges
class AchievementBadgeList extends StatelessWidget {
  final List<AchievementBadgeData> achievements;
  final String title;
  final EdgeInsets padding;

  const AchievementBadgeList({
    super.key,
    required this.achievements,
    this.title = 'Achievements',
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              if (achievements.isNotEmpty)
                Text(
                  '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: achievements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'achievement_badge_empty',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ).tr(),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(left: padding.left),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return AchievementBadge(
                      title: achievement.title,
                      description: achievement.description,
                      icon: achievement.icon,
                      isUnlocked: achievement.isUnlocked,
                      progress: achievement.progress,
                      customColor: achievement.customColor,
                      showProgress: achievement.showProgress,
                      progressText: achievement.progressText,
                      onTap: achievement.onTap,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Data class for achievement badges
class AchievementBadgeData {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress;
  final Color? customColor;
  final bool showProgress;
  final String? progressText;
  final VoidCallback? onTap;

  AchievementBadgeData({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.progress = 0.0,
    this.customColor,
    this.showProgress = false,
    this.progressText,
    this.onTap,
  });
}
