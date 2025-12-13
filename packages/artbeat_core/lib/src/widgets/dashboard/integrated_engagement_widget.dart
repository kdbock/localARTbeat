import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as artWalkLib;

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  final int currentCount;
  final int rewardXP;
  final String rewardDescription;
  final DateTime expiresAt;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.currentCount,
    required this.rewardXP,
    required this.rewardDescription,
    required this.expiresAt,
  });
}

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
  List<LeaderboardEntry> _topUsers = [];
  bool _isLoadingLeaderboard = true;

  late DailyChallenge _testChallenge;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTopUsers();
    _testChallenge = DailyChallenge(
      id: 'test_daily_challenge',
      title: 'Art Explorer',
      description: 'Discover 3 pieces of public art today',
      targetCount: 3,
      currentCount: 1,
      rewardXP: 100,
      rewardDescription: '🎨 Artist Badge + 100 XP',
      expiresAt: DateTime.now().add(const Duration(hours: 20)),
    );
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
                _buildTab(Icons.local_fire_department, 'Streak'),
                _buildTab(Icons.assignment, 'Daily'),
                _buildTab(Icons.calendar_today, 'Weekly'),
                _buildTab(Icons.emoji_events, 'Leaders'),
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
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
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
                const Text(
                  'Day Streak',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
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
                  '${(progressPercent * 100).round()}% of weekly goal',
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
                  label: 'Discoveries',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  color: Colors.orange,
                  value: '${widget.achievements.length}',
                  label: 'Badges',
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
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🔥 On Fire! Keep it up!',
                      style: TextStyle(
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
                    const Expanded(
                      child: Text(
                        'Weekly Goal',
                        style: TextStyle(
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
                  '${(progressPercent * 100).round()}% complete',
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
                      const Text(
                        'Activities Left',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(widget.weeklyGoal - widget.weeklyProgress).clamp(0, widget.weeklyGoal)} to complete goal',
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
            label: const Text('View Weekly Details'),
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
    final progress = _testChallenge.currentCount / _testChallenge.targetCount;

    return SingleChildScrollView(
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
                            _testChallenge.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expires in ${_testChallenge.expiresAt.difference(DateTime.now()).inHours}h',
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
                  _testChallenge.description,
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
                      '${_testChallenge.currentCount}/${_testChallenge.targetCount} Complete',
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
                      const Text(
                        'Reward',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _testChallenge.rewardDescription,
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
            onPressed: () {
              // Navigate to Art Walk Dashboard to start the quest
              Navigator.pushNamed(context, '/art-walk/dashboard');
            },
            icon: const Icon(Icons.explore),
            label: const Text('Start Quest'),
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
                    const Expanded(
                      child: Text(
                        'Top Contributors',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (widget.onLeaderboardTap != null)
                      GestureDetector(
                        onTap: widget.onLeaderboardTap,
                        child: const Text(
                          'View All',
                          style: TextStyle(
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
                        'No contributors yet',
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
                  label: const Text('Full Leaderboard'),
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
                  'Level ${user.level}',
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
                'XP',
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
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
