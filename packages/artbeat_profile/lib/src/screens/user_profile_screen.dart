import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final UserModel user = UserModel.placeholder();
  final List<Map<String, dynamic>> favorites = [];
  final List<Map<String, dynamic>> achievements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFollow() {
    // Replace with real follow logic
    setState(() {
      user.isFollowing = !user.isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeader(
                      avatarUrl: user.avatarUrl,
                      displayName: user.displayName,
                      handle: user.handle,
                      xpLevel: user.level,
                      badges: user.badges,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FollowButton(
                        isFollowing: user.isFollowing,
                        onTap: _toggleFollow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatBar(
                      followers: user.followers,
                      following: user.following,
                      favorites: user.favorites,
                      xp: user.xp,
                    ),
                    const SizedBox(height: 12),
                    XpProgressBar(
                      currentXp: user.xp,
                      currentLevel: user.level,
                      nextLevelXp: user.nextLevelXp,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabController,
                labelColor: ArtbeatColors.primaryPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: ArtbeatColors.primaryPurple,
                tabs: const [
                  Tab(text: 'Favorites'),
                  Tab(text: 'Achievements'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [_buildFavoritesTab(), _buildAchievementsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (favorites.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        message: 'No favorites yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        return FavoriteTile(
          id: (item['id'] ?? '') as String,
          title: (item['title'] ?? '') as String,
          description: (item['description'] ?? '') as String,
          imageUrl: (item['imageUrl'] ?? '') as String,
          metadata: item['metadata'] as Map<String, dynamic>?,
          isCurrentUser: false,
          onTap: () {
            // Handle favorite tap
          },
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );
  }

  Widget _buildAchievementsTab() {
    if (achievements.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        message: 'No achievements unlocked yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementTile(achievement: achievement);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );
  }
}
