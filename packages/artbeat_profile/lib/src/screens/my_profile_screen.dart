import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return MainLayout(
      currentIndex: 3,
      child: Scaffold(
        body: WorldBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HudTopBar(title: 'profile_my_title'.tr()),

                  const SizedBox(height: 16),
                  // Profile Header
                  ProfileHeader(userId: user?.uid ?? ''),

                  const SizedBox(height: 24),
                  // XP Progress Bar
                  const XpProgressBar(
                    currentXp: 1320,
                    currentLevel: 4,
                    nextLevelXp: 1500,
                  ),

                  const SizedBox(height: 24),
                  // Stats
                  const StatBar(
                    followers: 128,
                    following: 93,
                    favorites: 42,
                    xp: 1320,
                  ),

                  const SizedBox(height: 32),
                  // Section - Achievements
                  SectionHeader(
                    icon: Icons.emoji_events,
                    title: 'profile_my_achievements_title'.tr(),
                    onViewAll: () =>
                        Navigator.pushNamed(context, '/profile/achievements'),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        AchievementTile(
                          title: 'Art Explorer',
                          description: 'Complete 5 Art Walks',
                          icon: Icons.map_outlined,
                          earned: true,
                          xp: 75,
                        ),
                        AchievementTile(
                          title: 'Street Photographer',
                          description: 'Add 3 Art Captures',
                          icon: Icons.camera_alt_outlined,
                          earned: false,
                          currentXp: 2,
                          xp: 3,
                        ),
                        AchievementTile(
                          title: 'Walk Creator',
                          description: 'Create 1 Art Walk',
                          icon: Icons.directions_walk,
                          earned: false,
                          currentXp: 0,
                          xp: 1,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Section - Favorites
                  SectionHeader(
                    icon: Icons.favorite_border,
                    title: 'profile_favorites'.tr(),
                    onViewAll: () =>
                        Navigator.pushNamed(context, '/profile/favorites'),
                  ),

                  const SizedBox(height: 12),
                  const GlassCard(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: ArtbeatColors.primaryPurple,
                        ),
                        SizedBox(width: 12),
                        Text('Favorite artworks, captures and more...'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Section - Settings
                  SectionHeader(
                    icon: Icons.settings,
                    title: 'profile_settings'.tr(),
                  ),

                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: Text('profile_edit_profile'.tr()),
                          onTap: () =>
                              Navigator.pushNamed(context, '/profile/edit'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: Text('profile_account_settings'.tr()),
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: Text('profile_logout'.tr()),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
