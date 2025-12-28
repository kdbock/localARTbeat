import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_art_walk/src/models/challenge_model.dart';
import 'package:artbeat_art_walk/src/services/challenge_service.dart';
import 'package:artbeat_art_walk/src/widgets/daily_quest_card.dart';

/// Quest History Screen
/// Shows all past and current quests with statistics
class QuestHistoryScreen extends StatefulWidget {
  const QuestHistoryScreen({super.key});

  @override
  State<QuestHistoryScreen> createState() => _QuestHistoryScreenState();
}

class _QuestHistoryScreenState extends State<QuestHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final ChallengeService _challengeService;

  ChallengeModel? _todaysChallenge;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _challengeService = context.read<ChallengeService>();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final challenge = await _challengeService.getTodaysChallenge();
      final stats = await _challengeService.getChallengeStats();
      final completionRate = await _challengeService
          .getChallengeCompletionRate();

      setState(() {
        _todaysChallenge = challenge;
        _stats = {...stats, 'completionRate': completionRate};
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading quest data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Quest Journal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Stats'),
            Tab(text: 'All Quests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentQuestTab(),
                _buildStatsTab(),
                _buildAllQuestsTab(),
              ],
            ),
    );
  }

  Widget _buildCurrentQuestTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Today's quest
          DailyQuestCard(
            challenge: _todaysChallenge,
            showTimeRemaining: true,
            showRewardPreview: true,
          ),

          const SizedBox(height: 24),

          // Quick stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickStatCard(
                      icon: Icons.local_fire_department,
                      iconColor: ArtbeatColors.accentOrange,
                      value: '${_stats['currentStreak'] ?? 0}',
                      label: 'Day Streak',
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStatCard(
                      icon: Icons.check_circle,
                      iconColor: ArtbeatColors.primaryGreen,
                      value: '${_stats['completedChallenges'] ?? 0}',
                      label: 'Completed',
                    ),
                    const SizedBox(width: 12),
                    _buildQuickStatCard(
                      icon: Icons.stars,
                      iconColor: ArtbeatColors.primaryPurple,
                      value: '${_stats['totalXPEarned'] ?? 0}',
                      label: 'Total XP',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quest tips
          _buildQuestTips(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final completionRate =
        (_stats['completionRate'] as num?)?.toDouble() ?? 0.0;
    final completedChallenges = (_stats['completedChallenges'] as int?) ?? 0;
    final totalXP = (_stats['totalXPEarned'] as int?) ?? 0;
    final currentStreak = (_stats['currentStreak'] as int?) ?? 0;
    final bestStreak = (_stats['bestStreak'] as int?) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall stats card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ArtbeatColors.primaryPurple,
                  ArtbeatColors.primaryBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Quest Master Level',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getQuestMasterLevel(completedChallenges),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getQuestMasterTitle(completedChallenges),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detailed stats
          _buildStatRow(
            'Completion Rate',
            '${(completionRate * 100).toStringAsFixed(1)}%',
            Icons.trending_up,
            ArtbeatColors.primaryGreen,
          ),
          _buildStatRow(
            'Total Quests Completed',
            '$completedChallenges',
            Icons.check_circle,
            ArtbeatColors.primaryBlue,
          ),
          _buildStatRow(
            'Total XP Earned',
            '$totalXP',
            Icons.stars,
            ArtbeatColors.accentOrange,
          ),
          _buildStatRow(
            'Current Streak',
            '$currentStreak days',
            Icons.local_fire_department,
            ArtbeatColors.accentOrange,
          ),
          _buildStatRow(
            'Best Streak',
            '$bestStreak days',
            Icons.emoji_events,
            Colors.amber,
          ),

          const SizedBox(height: 24),

          // Achievement milestones
          _buildMilestones(completedChallenges),
        ],
      ),
    );
  }

  Widget _buildAllQuestsTab() {
    final availableQuests = _challengeService.getAvailableChallengeTypes();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableQuests.length,
      itemBuilder: (context, index) {
        final questType = availableQuests[index];
        return _buildQuestTypeCard(questType);
      },
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestTips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                    color: ArtbeatColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: ArtbeatColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quest Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem('Complete quests daily to build your streak'),
            _buildTipItem('Higher streaks unlock bonus challenges'),
            _buildTipItem('Quest difficulty scales with your level'),
            _buildTipItem('Weekend quests focus on exploration'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: ArtbeatColors.primaryGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: ArtbeatColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(int completedChallenges) {
    final milestones = <Map<String, dynamic>>[
      {'count': 1, 'title': 'First Quest', 'icon': Icons.flag},
      {'count': 7, 'title': 'Week Warrior', 'icon': Icons.calendar_today},
      {'count': 30, 'title': 'Month Master', 'icon': Icons.calendar_month},
      {'count': 100, 'title': 'Century Club', 'icon': Icons.emoji_events},
      {'count': 365, 'title': 'Year Legend', 'icon': Icons.stars},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...milestones.map((milestone) {
          final count = milestone['count'] as int;
          final isAchieved = completedChallenges >= count;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAchieved
                  ? ArtbeatColors.primaryGreen.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAchieved
                    ? ArtbeatColors.primaryGreen
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  milestone['icon'] as IconData,
                  color: isAchieved ? ArtbeatColors.primaryGreen : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isAchieved
                              ? ArtbeatColors.textPrimary
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        'Complete $count quests',
                        style: TextStyle(
                          fontSize: 13,
                          color: isAchieved
                              ? ArtbeatColors.textSecondary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAchieved)
                  const Icon(
                    Icons.check_circle,
                    color: ArtbeatColors.primaryGreen,
                    size: 24,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestTypeCard(String questType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getQuestTypeIcon(questType),
              color: ArtbeatColors.primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
                Text(
                  _getQuestTypeDescription(questType),
                  style: const TextStyle(
                    fontSize: 13,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQuestMasterLevel(int completedChallenges) {
    if (completedChallenges >= 365) return 'Legend';
    if (completedChallenges >= 100) return 'Master';
    if (completedChallenges >= 30) return 'Expert';
    if (completedChallenges >= 7) return 'Apprentice';
    return 'Novice';
  }

  String _getQuestMasterTitle(int completedChallenges) {
    if (completedChallenges >= 365) return '🏆 Quest Legend';
    if (completedChallenges >= 100) return '⭐ Quest Master';
    if (completedChallenges >= 30) return '🎯 Quest Expert';
    if (completedChallenges >= 7) return '📚 Quest Apprentice';
    return '🌱 Quest Novice';
  }

  IconData _getQuestTypeIcon(String questType) {
    if (questType.contains('Explorer')) return Icons.explore;
    if (questType.contains('Photo')) return Icons.camera_alt;
    if (questType.contains('Walk')) return Icons.directions_walk;
    if (questType.contains('Share')) return Icons.share;
    if (questType.contains('Community')) return Icons.people;
    if (questType.contains('Step')) return Icons.directions_run;
    if (questType.contains('Early Bird')) return Icons.wb_sunny;
    if (questType.contains('Night Owl')) return Icons.nightlight;
    if (questType.contains('Golden Hour')) return Icons.wb_twilight;
    if (questType.contains('Critic')) return Icons.rate_review;
    if (questType.contains('Style')) return Icons.palette;
    if (questType.contains('Streak')) return Icons.local_fire_department;
    if (questType.contains('Neighborhood')) return Icons.location_city;
    return Icons.flag;
  }

  String _getQuestTypeDescription(String questType) {
    final descriptions = {
      'Art Explorer': 'Discover new pieces of public art',
      'Neighborhood Scout': 'Explore art in different neighborhoods',
      'Photo Hunter': 'Capture photos of artworks',
      'Golden Hour Artist': 'Photograph art during golden hour',
      'Art Sharer': 'Share discoveries with friends',
      'Community Connector': 'Engage with other art lovers',
      'Urban Wanderer': 'Walk while exploring art',
      'Step Master': 'Stay active on your art journey',
      'Early Bird Explorer': 'Discover art in the morning',
      'Night Owl Artist': 'Capture illuminated artworks',
      'Art Critic': 'Write detailed artwork descriptions',
      'Style Collector': 'Find diverse art styles',
      'Streak Warrior': 'Maintain your daily streak',
    };

    return descriptions[questType] ?? 'Complete this quest for rewards';
  }
}
