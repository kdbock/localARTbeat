import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'achievement_runner.dart';
import 'achievement_badge.dart';

/// A comprehensive user experience card that displays:
/// - User level progression with AchievementRunner
/// - Recent badges earned
/// - Achievement progress overview
/// - Level perks preview
class UserExperienceCard extends StatefulWidget {
  final UserModel user;
  final List<AchievementBadgeData> achievements;
  final VoidCallback? onTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onAchievementsTap;
  final bool showAnimations;
  final EdgeInsets margin;

  const UserExperienceCard({
    super.key,
    required this.user,
    this.achievements = const [],
    this.onTap,
    this.onProfileTap,
    this.onAchievementsTap,
    this.showAnimations = true,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  State<UserExperienceCard> createState() => _UserExperienceCardState();
}

class _UserExperienceCardState extends State<UserExperienceCard>
    with TickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  List<AchievementBadgeData> get _recentAchievements =>
      widget.achievements.where((a) => a.isUnlocked).take(3).toList();

  int get _unlockedCount =>
      widget.achievements.where((a) => a.isUnlocked).length;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    // Start collapsed
    _expandController.value = 0.0;
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              ArtbeatColors.primaryPurple.withValues(alpha: 0.02),
              ArtbeatColors.primaryGreen.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              _buildHeader(),

              // Collapsible content
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Achievement Runner - Main progress display
                    _buildAchievementRunner(),

                    const SizedBox(height: 20),

                    // Recent achievements section
                    if (widget.achievements.isNotEmpty)
                      _buildRecentAchievements(),

                    const SizedBox(height: 16),

                    // Level perks preview
                    _buildLevelPerks(),

                    const SizedBox(height: 12),

                    // Quick stats row
                    _buildQuickStats(),
                  ],
                ),
              ),

              // Collapsed state mini display
              if (!_isExpanded) _buildCollapsedView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // User avatar and name - tappable for profile
        Expanded(
          child: GestureDetector(
            onTap: widget.onProfileTap,
            child: Row(
              children: [
                // User avatar
                _buildUserAvatar(),

                const SizedBox(width: 16),

                // User name and greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ux_card_welcome_back'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.fullName.isNotEmpty
                            ? widget.user.fullName.split(' ').first
                            : widget.user.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // New achievements indicator
        if (_recentAchievements.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ArtbeatColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: ArtbeatColors.warning, size: 16),
                const SizedBox(width: 4),
                Text(
                  'ux_card_new_badge'.tr(),
                  style: const TextStyle(
                    color: ArtbeatColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Collapse/Expand button
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
              ),
            ),
            child: RotationTransition(
              turns: Tween<double>(
                begin: 0.0,
                end: 0.5,
              ).animate(_expandController),
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: ArtbeatColors.primaryPurple,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OptimizedAvatar(
        key: ValueKey<String>(
          'user_avatar_${widget.user.id}_${widget.user.profileImageUrl}',
        ),
        imageUrl: widget.user.profileImageUrl.isNotEmpty
            ? widget.user.profileImageUrl
            : null,
        displayName: widget.user.fullName.isNotEmpty
            ? widget.user.fullName
            : widget.user.username.isNotEmpty
            ? widget.user.username
            : 'drawer_user_default'.tr(),
        radius: 25,
        backgroundColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        textColor: ArtbeatColors.primaryPurple,
      ),
    );
  }

  Widget _buildAchievementRunner() {
    final levelTitle = _rewardsService.getLevelTitle(widget.user.level);
    final progress = _rewardsService.getLevelProgress(
      widget.user.experiencePoints,
      widget.user.level,
    );

    return AchievementRunner(
      progress: progress,
      currentLevel: widget.user.level,
      experiencePoints: widget.user.experiencePoints,
      levelTitle: levelTitle,
      showAnimations: widget.showAnimations,
      height: 45,
      margin: EdgeInsets.zero,
    );
  }

  Widget _buildRecentAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: ArtbeatColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'ux_card_achievements'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$_unlockedCount/${widget.achievements.length}',
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.achievements.isNotEmpty)
              GestureDetector(
                onTap: widget.onAchievementsTap,
                child: Text(
                  'ux_card_view_all'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Recent achievements display
        if (_recentAchievements.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _recentAchievements.map((achievement) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: widget.onAchievementsTap,
                    child: _buildMiniAchievementBadge(
                      achievement.title,
                      achievement.icon,
                      achievement.description,
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ux_card_empty_achievements'.tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMiniAchievementBadge(
    String title,
    IconData icon,
    String description,
  ) {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: ArtbeatColors.primaryPurple,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: ArtbeatColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelPerks() {
    final perks = _rewardsService.getLevelPerks(widget.user.level);
    final nextLevelPerks = _rewardsService.getLevelPerks(widget.user.level + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lock_open,
              color: ArtbeatColors.primaryGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'ux_card_level_perks'.tr(
                namedArgs: {'level': widget.user.level.toString()},
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (perks.isNotEmpty)
          ...perks
              .take(2)
              .map(
                (perk) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: ArtbeatColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          perk,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
        else
          Text(
            'ux_card_no_perks'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),

        // Next level preview
        if (nextLevelPerks.isNotEmpty && widget.user.level < 10)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: ArtbeatColors.primaryPurple,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'achievement_next_level_prefix'.tr()}: ${nextLevelPerks.first}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ArtbeatColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.directions_walk,
            label: 'ux_card_level'.tr(),
            value: widget.user.level.toString(),
            color: ArtbeatColors.primaryPurple,
          ),
          _buildStatItem(
            icon: Icons.star,
            label: 'ux_card_xp'.tr(),
            value: widget.user.experiencePoints.toString(),
            color: ArtbeatColors.primaryGreen,
          ),
          _buildStatItem(
            icon: Icons.emoji_events,
            label: 'ux_card_badges'.tr(),
            value: _unlockedCount.toString(),
            color: ArtbeatColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ArtbeatColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedView() {
    final levelTitle = _rewardsService.getLevelTitle(widget.user.level);
    final progress = _rewardsService.getLevelProgress(
      widget.user.experiencePoints,
      widget.user.level,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'ux_card_level'.tr()} ${widget.user.level}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ArtbeatColors.primaryPurple,
                          ),
                        ),
                        Text(
                          '${widget.user.experiencePoints} ${'ux_card_xp'.tr()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ArtbeatColors.primaryPurple,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      levelTitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ArtbeatColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.achievements.isNotEmpty) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: widget.onAchievementsTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ux_card_badges_count'.tr(
                        namedArgs: {'count': _unlockedCount.toString()},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ArtbeatColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
