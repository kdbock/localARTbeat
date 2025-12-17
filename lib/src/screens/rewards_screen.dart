import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Rewards Screen - Displays and manages user rewards, XP, and achievements
///
/// This screen provides a comprehensive rewards management interface including:
/// - User XP and level progress
/// - Badge and achievement display
/// - Rewards redemption (for admin users)
/// - Level perks and unlockables
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  final RewardsService rewardsService = RewardsService();
  final UserService userService = UserService();

  UserModel? currentUser;
  Map<String, dynamic> userBadges = {};
  List<String> unviewedBadges = [];
  bool isLoading = true;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    loadRewardsData();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> loadRewardsData() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user data
        currentUser = await userService.getCurrentUserModel();

        // Load badges
        userBadges = await rewardsService.getUserBadges(user.uid);
        unviewedBadges = await rewardsService.getUnviewedBadges(user.uid);
      }
    } on Exception catch (e) {
      AppLogger.error('Error loading rewards data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rewards & Achievements'),
      backgroundColor: ArtbeatColors.primaryPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: TabBar(
        controller: tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
          Tab(text: 'Badges', icon: Icon(Icons.emoji_events)),
          Tab(text: 'Perks', icon: Icon(Icons.star)),
        ],
      ),
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: tabController,
            children: [
              _buildOverviewTab(),
              _buildBadgesTab(),
              _buildPerksTab(),
            ],
          ),
  );

  Widget _buildOverviewTab() {
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view your rewards'));
    }

    final userData = currentUser;

    // Get user stats from Firestore or use defaults
    final xp = userData?.experiencePoints;
    final levelTitle = rewardsService.getLevelTitle(userData!.level);
    final levelRange = rewardsService.getLevelXPRange(userData.level);
    final progress = rewardsService.getLevelProgress(xp!, userData.level);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User XP and Level Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  blurRadius: 10,
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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${userData.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            levelTitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${levelRange['max']! - xp} XP to next level',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Achievements
          const Text(
            'Recent Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: unviewedBadges.length,
              itemBuilder: (context, index) {
                final badgeId = unviewedBadges[index];
                final badge = RewardsService.badges[badgeId];
                if (badge == null) return const SizedBox.shrink();

                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          badge['icon'] as String,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            badge['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primaryGreen,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // User Statistics
          const Text(
            'Your Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Captures',
                '${userData.capturesCount}',
                Icons.camera_alt,
                ArtbeatColors.primaryPurple,
              ),
              _buildStatCard(
                'Posts',
                '${userData.postsCount}',
                Icons.post_add,
                ArtbeatColors.primaryGreen,
              ),
              _buildStatCard(
                'Connections',
                '${userData.connectionsCount}',
                Icons.people,
                ArtbeatColors.accentOrange,
              ),
              _buildStatCard(
                'Level',
                '${userData.level}',
                Icons.trending_up,
                ArtbeatColors.primaryPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    ),
  );

  Widget _buildBadgesTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Badge Collection',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
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
            final isUnlocked = userBadges.containsKey(badgeId);
            final isNew = unviewedBadges.contains(badgeId);

            return DecoratedBox(
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: isNew
                    ? Border.all(color: ArtbeatColors.primaryGreen, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
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
                            color: isUnlocked ? null : Colors.grey,
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
                            color: isUnlocked ? Colors.grey[600] : Colors.grey,
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
                          color: ArtbeatColors.primaryGreen,
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

  Widget _buildPerksTab() {
    final currentLevel = currentUser?.level ?? 1;
    final perks = rewardsService.getLevelPerks(currentLevel);
    final nextLevelPerks = rewardsService.getLevelPerks(currentLevel + 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Level Perks
          const Text(
            'Your Current Perks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          if (perks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No perks unlocked at this level yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...perks.map((perk) => _buildPerkCard(perk, true)),

          const SizedBox(height: 24),

          // Next Level Perks
          const Text(
            'Unlock at Next Level',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          if (nextLevelPerks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No additional perks at the next level.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...nextLevelPerks.map((perk) => _buildPerkCard(perk, false)),
        ],
      ),
    );
  }

  Widget _buildPerkCard(String perk, bool isUnlocked) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isUnlocked ? Colors.white : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isUnlocked ? ArtbeatColors.primaryGreen : Colors.grey[300]!,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked
                ? ArtbeatColors.primaryGreen.withValues(alpha: 0.1)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            isUnlocked ? Icons.check_circle : Icons.lock,
            color: isUnlocked ? ArtbeatColors.primaryGreen : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            perk,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ],
    ),
  );
}
