import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;
import 'package:artbeat_art_walk/src/models/challenge_model.dart';
import 'package:artbeat_art_walk/src/services/challenge_service.dart';
import 'package:artbeat_art_walk/src/widgets/daily_quest_card.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

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
    return WorldBackground(
      child: Column(
        children: [
          HudTopBar(
            title: 'art_walk_quest_history_title'.tr(),
            showBack: true,
            onBack: () => Navigator.of(context).pop(),
          ),

          Material(
            color: Colors.transparent,
            child: TabBar(
              controller: _tabController,
              indicatorColor: ArtbeatColors.primaryPurple,
              labelColor: Colors.white,
              unselectedLabelColor: const Color.fromARGB(
                115,
                255,
                255,
                255,
              ), // ~45% alpha
              tabs: [
                Tab(text: 'art_walk_quest_tab_current'.tr()),
                Tab(text: 'art_walk_quest_tab_stats'.tr()),
                Tab(text: 'art_walk_quest_tab_all'.tr()),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      Container(
                        color: Colors.transparent,
                        child: _buildCurrentQuestTab(),
                      ),
                      Container(
                        color: Colors.transparent,
                        child: _buildStatsTab(),
                      ),
                      Container(
                        color: Colors.transparent,
                        child: _buildAllQuestsTab(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentQuestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          if (_todaysChallenge != null)
            GlassCard(
              padding: const EdgeInsets.all(16),
              fillColor: const Color.fromARGB(18, 255, 255, 255), // ~7% alpha
              child: DailyQuestCard(
                challenge: _todaysChallenge,
                showTimeRemaining: true,
                showRewardPreview: true,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'art_walk_quest_your_progress'.tr(),
            style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatTile(
                'day_streak_label',
                Icons.local_fire_department,
                (_stats['currentStreak'] as int? ?? 0),
                ArtbeatColors.secondaryTeal,
              ),
              const SizedBox(width: 8),
              _buildStatTile(
                'completed_label',
                Icons.check_circle,
                (_stats['completedChallenges'] as int? ?? 0),
                ArtbeatColors.primaryGreen,
              ),
              const SizedBox(width: 8),
              _buildStatTile(
                'total_xp_label',
                Icons.stars,
                (_stats['totalXPEarned'] as int? ?? 0),
                ArtbeatColors.primaryPurple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(16),
            fillColor: const Color.fromARGB(18, 255, 255, 255),
            child: _buildQuestTips(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String labelKey,
    IconData icon,
    int value,
    Color color,
  ) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        fillColor: const Color.fromARGB(18, 255, 255, 255),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value.toString(), style: AppTextStyles.statValue),
            Text(
              labelKey.tr(),
              style: AppTextStyles.statLabel,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ArtbeatColors.primaryPurple.withValues(alpha: 0.85),
                      ArtbeatColors.secondaryTeal.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'quest_master_level_label'.tr(),
                      style: AppTextStyles.cardCaptionWhite,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getQuestMasterLevel(completedChallenges),
                      style: AppTextStyles.cardTitleWhite,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getQuestMasterTitle(completedChallenges),
                      style: AppTextStyles.cardSubtitleWhite,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatRow(
            'completion_rate_label'.tr(),
            '${(completionRate * 100).toStringAsFixed(1)}%',
            Icons.trending_up,
          ),
          _buildStatRow(
            'total_quests_completed_label'.tr(),
            '$completedChallenges',
            Icons.check_circle,
          ),
          _buildStatRow('total_xp_label'.tr(), '$totalXP', Icons.stars),
          _buildStatRow(
            'current_streak_label'.tr(),
            '$currentStreak',
            Icons.local_fire_department,
          ),
          _buildStatRow(
            'best_streak_label'.tr(),
            '$bestStreak',
            Icons.emoji_events,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        fillColor: const Color.fromARGB(18, 255, 255, 255),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            Text(value, style: AppTextStyles.bodyBold),
          ],
        ),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            fillColor: const Color.fromARGB(18, 255, 255, 255),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(questType, style: AppTextStyles.bodyBold),
                      Text(
                        _getQuestTypeDescription(questType),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestTips() {
    final tips = [
      'tip_quest_streak',
      'tip_bonus_challenges',
      'tip_scaling_difficulty',
      'tip_weekend_focus',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quest_tips_title'.tr(),
          style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        ...tips.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: ArtbeatColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key.tr(),
                    style: AppTextStyles.body.copyWith(
                      color: const Color.fromARGB(235, 255, 255, 255),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  String _getQuestTypeDescription(String questType) {
    final descriptions = {
      'Art Explorer': 'art_walk_quest_type_explorer'.tr(),
      'Neighborhood Scout': 'art_walk_quest_type_neighborhood'.tr(),
      'Photo Hunter': 'art_walk_quest_type_photo'.tr(),
      'Golden Hour Artist': 'art_walk_quest_type_golden'.tr(),
      'Art Sharer': 'art_walk_quest_type_sharer'.tr(),
      'Community Connector': 'art_walk_quest_type_community'.tr(),
      'Urban Wanderer': 'art_walk_quest_type_wanderer'.tr(),
      'Step Master': 'art_walk_quest_type_step'.tr(),
      'Early Bird Explorer': 'art_walk_quest_type_early'.tr(),
      'Night Owl Artist': 'art_walk_quest_type_night'.tr(),
      'Art Critic': 'art_walk_quest_type_critic'.tr(),
      'Style Collector': 'art_walk_quest_type_style'.tr(),
      'Streak Warrior': 'art_walk_quest_type_streak'.tr(),
    };
    return descriptions[questType] ?? 'art_walk_quest_type_default'.tr();
  }
}
