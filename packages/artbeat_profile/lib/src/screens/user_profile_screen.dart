import 'package:flutter/material.dart';
//
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_profile/src/widgets/world_background.dart';
import 'package:artbeat_profile/src/widgets/glass_card.dart';
import 'package:artbeat_profile/src/widgets/profile_header.dart';
import 'package:artbeat_profile/src/widgets/enhanced_stats_grid.dart';

import 'package:artbeat_profile/src/widgets/dynamic_achievements_tab.dart';
import 'package:artbeat_profile/src/widgets/progress_tab.dart';
import 'package:artbeat_profile/src/widgets/hud_top_bar.dart';
import 'package:artbeat_profile/src/widgets/empty_state.dart';
import 'package:artbeat_profile/src/widgets/follow_button.dart';
import 'package:easy_localization/easy_localization.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<core.UserModel?> _userFuture;
  final _userService = core.UserService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUserById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: FutureBuilder<core.UserModel?>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return EmptyState(
                  icon: Icons.person_off,
                  message: 'profile.user_not_found'.tr(),
                );
              }
              final user = snapshot.data!;
              final isCurrentUser = _currentUser?.uid == user.id;
              return Column(
                children: [
                  HudTopBar(
                    title: isCurrentUser ? 'My Profile' : user.displayName,
                    actions: [
                      if (isCurrentUser)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed('/edit_profile', arguments: user.id);
                          },
                        ),
                      if (!isCurrentUser)
                        FollowButton(
                          isFollowing: user.isFollowing,
                          onTap: () {
                            // TODO: Implement follow/unfollow logic
                          },
                        ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassCard(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ProfileHeader(
                              avatarUrl: user.avatarUrl,
                              displayName: user.displayName,
                              handle: user.handle,
                              xpLevel: user.level,
                              badges: user.badges,
                              userId: user.id,
                              user: user,
                            ),
                          ),
                          GlassCard(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: EnhancedStatsGrid(
                              posts: user.posts.length,
                              captures: user.captures.length,
                              artWalks: 0, // Not available in UserModel
                              likes: user.engagementStats.likeCount,
                              shares: user.engagementStats.shareCount,
                              comments: user.engagementStats.commentCount,
                              followers: user.engagementStats.followCount,
                              following: 0, // Not available in UserModel
                            ),
                          ),
                          // Optionally, add badges or achievements carousel if available in the future
                          GlassCard(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: DefaultTabController(
                              length: 3,
                              child: Column(
                                children: [
                                  TabBar(
                                    labelColor: Colors.deepPurpleAccent,
                                    unselectedLabelColor: Colors.white70,
                                    indicatorColor: Colors.deepPurpleAccent,
                                    tabs: const [
                                      Tab(text: 'Achievements'),
                                      Tab(text: 'Progress'),
                                      Tab(text: 'Favorites'),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 320,
                                    child: TabBarView(
                                      children: [
                                        DynamicAchievementsTab(userId: user.id),
                                        ProgressTab(userId: user.id),
                                        // TODO: Replace with FavoritesTab or similar
                                        Center(
                                          child: Text(
                                            'Favorites coming soon',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
