import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as artWalkLib;

class IntegratedEngagementWidget extends StatefulWidget {
  final UserModel user;
  final int currentStreak;
  final int totalDiscoveries;
  final int weeklyProgress;
  final int weeklyGoal;
  final List<artWalkLib.AchievementModel> achievements;
  final List<artWalkLib.SocialActivity> activities;
  final VoidCallback? onProfileTap;
  final VoidCallback? onAchievementsTap;
  final VoidCallback? onWeeklyGoalsTap;
  final VoidCallback? onLeaderboardTap;

  const IntegratedEngagementWidget({
    Key? key,
    required this.user,
    this.currentStreak = 0,
    this.totalDiscoveries = 0,
    this.weeklyProgress = 0,
    this.weeklyGoal = 7,
    this.achievements = const [],
    this.activities = const [],
    this.onProfileTap,
    this.onAchievementsTap,
    this.onWeeklyGoalsTap,
    this.onLeaderboardTap,
  }) : super(key: key);

  @override
  State<IntegratedEngagementWidget> createState() =>
      _IntegratedEngagementWidgetState();
}

class _IntegratedEngagementWidgetState extends State<IntegratedEngagementWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final LeaderboardService _leaderboardService = LeaderboardService();
  final artWalkLib.ChallengeService _challengeService =
      artWalkLib.ChallengeService();
  List<LeaderboardEntry> _topUsers = [];
  bool _isLoadingLeaderboard = true;
  artWalkLib.ChallengeModel? _dailyChallenge;
  bool _isLoadingDailyChallenge = true;
  String? _dailyChallengeError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTopUsers();
    _loadDailyChallenge();
  }

  Future<void> _loadTopUsers() async {
    try {
      final topUsers = await _leaderboardService.getLeaderboard(
        LeaderboardCategory.totalXP,
        limit: 5,
      );
      if (!mounted) return;
      setState(() {
        _topUsers = topUsers;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      AppLogger.error('Error loading top users: $e');
      if (!mounted) return;
      setState(() => _isLoadingLeaderboard = false);
    }
  }

  Future<void> _loadDailyChallenge() async {
    setState(() {
      _isLoadingDailyChallenge = true;
      _dailyChallengeError = null;
    });

    try {
      final challenge = await _challengeService.getTodaysChallenge();
      if (!mounted) return;
      setState(() {
        _dailyChallenge = challenge;
        _isLoadingDailyChallenge = false;
      });
    } catch (e) {
      AppLogger.error('Error loading daily challenge: $e');
      if (!mounted) return;
      setState(() {
        _dailyChallengeError = 'Unable to load daily quest';
        _isLoadingDailyChallenge = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Tab bar with gradient underline
          Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              tabs: [
                _buildTab(
                  Icons.local_fire_department,
                  'engagement_tab_streak'.tr(),
                ),
                _buildTab(Icons.assignment, 'engagement_tab_daily'.tr()),
                _buildTab(Icons.calendar_today, 'engagement_tab_weekly'.tr()),
                _buildTab(Icons.emoji_events, 'engagement_tab_leaders'.tr()),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStreakTab(),
                _buildDailyQuestTab(),
                _buildWeeklyTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStreakTab() {
    final progressPercent = widget.weeklyGoal > 0
        ? widget.weeklyProgress / widget.weeklyGoal
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ArtbeatColors.primaryPurple,
                  ArtbeatColors.primaryGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.currentStreak}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'engagement_day_streak'.tr(),
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'engagement_weekly_goal_percent'.tr(
                    namedArgs: {
                      'percent': (progressPercent * 100).round().toString(),
                    },
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.explore,
                  color: Colors.blue,
                  value: '${widget.totalDiscoveries}',
                  label: 'engagement_discoveries'.tr(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  color: Colors.orange,
                  value: '${widget.achievements.length}',
                  label: 'engagement_badges'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Achievement info
          if (widget.currentStreak >= 7)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'engagement_on_fire'.tr(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    final progressPercent = widget.weeklyGoal > 0
        ? widget.weeklyProgress / widget.weeklyGoal
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly progress card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ArtbeatColors.primaryGreen,
                  ArtbeatColors.primaryPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ArtbeatColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'engagement_weekly_goal'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.weeklyProgress}/${widget.weeklyGoal}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'engagement_percent_complete'.tr(
                    namedArgs: {
                      'percent': (progressPercent * 100).round().toString(),
                    },
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Remaining count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pending_actions, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'engagement_activities_left'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'engagement_to_complete_goal'.tr(
                          namedArgs: {
                            'count': (widget.weeklyGoal - widget.weeklyProgress)
                                .clamp(0, widget.weeklyGoal)
                                .toString(),
                          },
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onWeeklyGoalsTap,
            icon: const Icon(Icons.trending_up),
            label: Text('dashboard_view_weekly_details'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestTab() {
    if (_isLoadingDailyChallenge) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dailyChallengeError != null) {
      return _buildDailyQuestMessage(
        icon: Icons.error_outline,
        title: 'common_error'.tr(),
        subtitle: _dailyChallengeError!,
        buttonLabel: 'common_retry'.tr(),
        onPressed: _loadDailyChallenge,
      );
    }

    final challenge = _dailyChallenge;
    if (challenge == null) {
      return _buildDailyQuestMessage(
        icon: Icons.explore,
        title: 'daily_quest_label'.tr(),
        subtitle: 'daily_quest_unlock_subtitle'.tr(),
        buttonLabel: 'dashboard_start_quest'.tr(),
        onPressed: () => Navigator.pushNamed(context, '/art-walk/dashboard'),
      );
    }

    final progress = challenge.progressPercentage;
    final hoursRemaining = challenge.expiresAt.isBefore(DateTime.now())
        ? 0
        : challenge.expiresAt.difference(DateTime.now()).inHours;

    return RefreshIndicator(
      onRefresh: _loadDailyChallenge,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'engagement_expires_in'.tr(
                                namedArgs: {'hours': hoursRemaining.toString()},
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    challenge.description,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'engagement_progress_complete'.tr(
                          namedArgs: {
                            'current': challenge.currentCount.toString(),
                            'target': challenge.targetCount.toString(),
                          },
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'engagement_reward'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.rewardDescription.isNotEmpty
                              ? challenge.rewardDescription
                              : '${challenge.rewardXP} ${'achievement_xp_suffix'.tr()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/art-walk/dashboard'),
              icon: const Icon(Icons.explore),
              label: Text('dashboard_start_quest'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuestMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ArtbeatColors.primaryPurple),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ArtbeatColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 44),
                ),
                child: Text(buttonLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _isLoadingLeaderboard
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'engagement_top_contributors'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (widget.onLeaderboardTap != null)
                      GestureDetector(
                        onTap: widget.onLeaderboardTap,
                        child: Text(
                          'engagement_view_all'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ArtbeatColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_topUsers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'engagement_no_contributors'.tr(),
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _topUsers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      return _buildLeaderboardRow(user, index);
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed:
                      widget.onLeaderboardTap ??
                      () => Navigator.pushNamed(context, '/leaderboard'),
                  icon: const Icon(Icons.explore),
                  label: Text('dashboard_full_leaderboard'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(user.rank).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${user.rank}',
                style: TextStyle(
                  color: _getRankColor(user.rank),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'engagement_level'.tr(
                    namedArgs: {'level': user.level.toString()},
                  ),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatNumber(user.experiencePoints)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.primaryPurple,
                  fontSize: 14,
                ),
              ),
              Text(
                'engagement_xp'.tr(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return ArtbeatColors.primaryPurple;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return 'engagement_xp_suffix_m'.tr(
        namedArgs: {'value': (number / 1000000).toStringAsFixed(1)},
      );
    } else if (number >= 1000) {
      return 'engagement_xp_suffix_k'.tr(
        namedArgs: {'value': (number / 1000).toStringAsFixed(1)},
      );
    }
    return number.toString();
  }
}
