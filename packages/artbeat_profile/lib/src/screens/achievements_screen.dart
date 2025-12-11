import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' hide AchievementModel;
import 'package:artbeat_core/artbeat_core.dart';
// Import with alias to avoid conflicts
import 'package:artbeat_art_walk/src/services/achievement_service.dart'
    as art_walk;
import 'package:artbeat_art_walk/src/models/achievement_model.dart'
    as art_walk_model;
import 'package:easy_localization/easy_localization.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final art_walk.AchievementService _achievementService =
      art_walk.AchievementService();
  bool _isLoading = true;
  List<art_walk_model.AchievementModel> _achievements = [];
  Map<String, List<art_walk_model.AchievementModel>> _categorizedAchievements =
      {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      AppLogger.info('DEBUG: Loading achievements for user...');
      final achievements = await _achievementService.getUserAchievements();
      AppLogger.info('DEBUG: Found ${achievements.length} achievements');

      // Debug: Print each achievement
      for (final achievement in achievements) {
        debugPrint(
          'DEBUG: Achievement - ${achievement.type.name}: ${achievement.title}',
        );
      }

      // Mark any new achievements as viewed
      for (final achievement in achievements.where((a) => a.isNew)) {
        await _achievementService.markAchievementAsViewed(achievement.id);
      }

      // Categorize achievements
      final Map<String, List<art_walk_model.AchievementModel>> categorized = {
        'Art Walks': [],
        'Art Discovery': [],
        'Contributions': [],
        'Social': [],
      };

      for (final achievement in achievements) {
        switch (achievement.type) {
          case art_walk_model.AchievementType.firstWalk:
          case art_walk_model.AchievementType.walkExplorer:
          case art_walk_model.AchievementType.walkMaster:
          case art_walk_model.AchievementType.marathonWalker:
            categorized['Art Walks']!.add(achievement);
            break;
          case art_walk_model.AchievementType.artCollector:
          case art_walk_model.AchievementType.artExpert:
          case art_walk_model.AchievementType.photographer:
            categorized['Art Discovery']!.add(achievement);
            break;
          case art_walk_model.AchievementType.contributor:
          case art_walk_model.AchievementType.curator:
          case art_walk_model.AchievementType.masterCurator:
            categorized['Contributions']!.add(achievement);
            break;
          case art_walk_model.AchievementType.commentator:
          case art_walk_model.AchievementType.socialButterfly:
          case art_walk_model.AchievementType.earlyAdopter:
            categorized['Social']!.add(achievement);
            break;
        }
      }

      setState(() {
        _achievements = achievements;
        _categorizedAchievements = categorized;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('DEBUG: Error loading achievements: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_achievements_screen_error_error_loading_achievements'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  void _showAchievementDetails(art_walk_model.AchievementModel achievement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getAchievementColors(achievement),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getAchievementIcon(achievement),
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                achievement.description,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Earned on ${_formatDate(achievement.earnedAt)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('profile_achievements_close'.tr()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getAchievementIcon(art_walk_model.AchievementModel achievement) {
    final String iconName = achievement.iconName;

    // Map the string icon name to actual IconData
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

  List<Color> _getAchievementColors(
    art_walk_model.AchievementModel achievement,
  ) {
    switch (achievement.type) {
      // "First" achievements - bronze
      case art_walk_model.AchievementType.firstWalk:
      case art_walk_model.AchievementType.artCollector:
      case art_walk_model.AchievementType.photographer:
      case art_walk_model.AchievementType.commentator:
      case art_walk_model.AchievementType.socialButterfly:
      case art_walk_model.AchievementType.curator:
      case art_walk_model.AchievementType.earlyAdopter:
        return [const Color(0xFFCD7F32), const Color(0xFFA05B20)];
      // Mid-level achievements - silver
      case art_walk_model.AchievementType.walkExplorer:
      case art_walk_model.AchievementType.artExpert:
      case art_walk_model.AchievementType.marathonWalker:
        return [const Color(0xFFC0C0C0), const Color(0xFF8a8a8a)];
      // Advanced achievements - gold
      case art_walk_model.AchievementType.walkMaster:
      case art_walk_model.AchievementType.contributor:
      case art_walk_model.AchievementType.masterCurator:
        return [const Color(0xFFFFD700), const Color(0xFFB7950B)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile_achievements_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Force refresh achievements
              await _loadAchievements();
              if (mounted) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('profile_achievements_refreshed'.tr())),
                );
              }
            },
            tooltip: 'Refresh Achievements',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: ArtbeatColors.primaryPurple,
          unselectedLabelColor: ArtbeatColors.textSecondary,
          indicatorColor: ArtbeatColors.primaryPurple,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Art Walks'),
            Tab(text: 'Art Discovery'),
            Tab(text: 'Social'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
              Colors.white,
              ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ArtbeatColors.primaryPurple,
                ),
              )
            : RefreshIndicator(
                color: ArtbeatColors.primaryPurple,
                onRefresh: _loadAchievements,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All achievements
                    _buildAchievementsTab(_achievements),

                    // Art Walks tab
                    _buildAchievementsTab(
                      _categorizedAchievements['Art Walks'] ?? [],
                    ),

                    // Art Discovery tab
                    _buildAchievementsTab(
                      _categorizedAchievements['Art Discovery'] ?? [],
                    ),

                    // Social tab
                    _buildAchievementsTab([
                      ...(_categorizedAchievements['Social'] ?? []),
                      ...(_categorizedAchievements['Contributions'] ?? []),
                    ]),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAchievementsTab(
    List<art_walk_model.AchievementModel> achievements,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievement Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have earned ${achievements.length} out of 13 possible achievements',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: achievements.length / 13,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAchievementStatItem(
                        'Bronze',
                        _countAchievementsByTier(achievements, 'bronze'),
                        const Color(0xFFCD7F32),
                      ),
                      _buildAchievementStatItem(
                        'Silver',
                        _countAchievementsByTier(achievements, 'silver'),
                        const Color(0xFFC0C0C0),
                      ),
                      _buildAchievementStatItem(
                        'Gold',
                        _countAchievementsByTier(achievements, 'gold'),
                        const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Achievements Grid
          AchievementsGrid(
            achievements: achievements,
            showDetails: true,
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            badgeSize: 80,
            onAchievementTap: _showAchievementDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStatItem(String name, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(128),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  int _countAchievementsByTier(
    List<art_walk_model.AchievementModel> achievements,
    String tier,
  ) {
    Set<art_walk_model.AchievementType> tierAchievements;

    switch (tier) {
      case 'bronze':
        tierAchievements = {
          art_walk_model.AchievementType.firstWalk,
          art_walk_model.AchievementType.artCollector,
          art_walk_model.AchievementType.photographer,
          art_walk_model.AchievementType.commentator,
          art_walk_model.AchievementType.socialButterfly,
          art_walk_model.AchievementType.curator,
          art_walk_model.AchievementType.earlyAdopter,
        };
        break;
      case 'silver':
        tierAchievements = {
          art_walk_model.AchievementType.walkExplorer,
          art_walk_model.AchievementType.artExpert,
          art_walk_model.AchievementType.marathonWalker,
        };
        break;
      case 'gold':
        tierAchievements = {
          art_walk_model.AchievementType.walkMaster,
          art_walk_model.AchievementType.contributor,
          art_walk_model.AchievementType.masterCurator,
        };
        break;
      default:
        return 0;
    }

    return achievements.where((a) => tierAchievements.contains(a.type)).length;
  }
}
