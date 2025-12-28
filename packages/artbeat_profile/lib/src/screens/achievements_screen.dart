import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_profile/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  List<AchievementModel> _achievements = [];
  Map<String, dynamic> _userBadges = {};
  List<String> _unviewedBadges = [];
  bool _isLoading = true;
  TabController? _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isInitialized = true;
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _isInitialized = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userService = context.read<UserService>();
      final achievementService = context.read<AchievementService>();
      final rewardsService = context.read<RewardsService>();

      _user = await userService.getCurrentUserModel();
      if (_user != null) {
        _achievements = await achievementService.getUserAchievements();
        _userBadges = await rewardsService.getUserBadges(_user!.id);
        _unviewedBadges = await rewardsService.getUnviewedBadges(_user!.id);
      }
    } catch (e) {
      // Handle error
      debugPrint('Error loading achievements: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const WorldBackground(
        child: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final user = _user;
    final achievements = _achievements;

    if (user == null) {
      return const WorldBackground(
        child: SafeArea(
          child: Column(
            children: [
              HudTopBar(title: 'Achievements', showBackButton: true),
              Expanded(
                child: Center(
                  child: Text('Please sign in to view achievements'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            const HudTopBar(title: 'Achievements', showBackButton: true),
            if (_isInitialized && _tabController != null) ...[
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Achievements', icon: Icon(Icons.emoji_events)),
                  Tab(text: 'Badges', icon: Icon(Icons.badge)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAchievementsTab(user, achievements),
                    _buildBadgesTab(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(
    UserModel user,
    List<AchievementModel> achievements,
  ) {
    return achievements.isEmpty
        ? const EmptyState(
            icon: Icons.emoji_events_outlined,
            message: 'No achievements yet — start exploring art walks!',
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level Progress',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    XpProgressBar(
                      currentXp: user.xp,
                      nextLevelXp: user.nextLevelXp,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.xp} XP / ${user.nextLevelXp} XP',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...achievements.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AchievementTile(achievement: a),
                ),
              ),
            ],
          );
  }

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Badge Collection',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: RewardsService.badges.length,
            itemBuilder: (context, index) {
              final badgeEntry = RewardsService.badges.entries.elementAt(index);
              final badgeId = badgeEntry.key;
              final badge = badgeEntry.value;
              final isUnlocked = _userBadges.containsKey(badgeId);
              final isNew = _unviewedBadges.contains(badgeId);

              return Container(
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  border: isNew
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            badge['icon'] as String,
                            style: TextStyle(
                              fontSize: 32,
                              color: isUnlocked ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge['description'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: isUnlocked
                                  ? Colors.grey[600]
                                  : Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isNew)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
