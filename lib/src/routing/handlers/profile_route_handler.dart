import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../guards/auth_guard.dart';
import '../route_utils.dart';

class ProfileRouteHandler {
  const ProfileRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/profile':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Profile not available')),
              );
            }

            final args = settings.arguments as Map<String, dynamic>?;
            final targetUserId = args?['userId'] as String? ?? currentUser.uid;
            final isCurrentUser = targetUserId == currentUser.uid;

            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar(
                isCurrentUser ? 'Profile' : 'User Profile',
              ),
              child: profile.ProfileViewScreen(
                userId: targetUserId,
                isCurrentUser: isCurrentUser,
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/edit':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Profile edit not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Edit Profile'),
              child: profile.EditProfileScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/picture':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final args = settings.arguments as Map<String, dynamic>?;
            final imageUrl = args?['imageUrl'] as String? ?? '';
            final userId =
                args?['userId'] as String? ??
                FirebaseAuth.instance.currentUser?.uid ??
                '';
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Profile Picture'),
              child: profile.ProfilePictureViewerScreen(
                imageUrl: imageUrl,
                userId: userId,
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/connections':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.ProfileConnectionsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/activity':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const _ProfileActivityWrapper(),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/analytics':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.ProfileAnalyticsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/achievements':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.AchievementsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/following':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Following not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              child: profile.FollowedArtistsScreen(
                userId: currentUser.uid,
                embedInMainLayout: false,
              ),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/followers':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Followers not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Followers'),
              child: profile.FollowersListScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/liked':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Liked content not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Liked Items'),
              child: profile.FavoritesScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/settings':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.ProfileSettingsScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/blocked':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Blocked users not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Blocked Users'),
              child: const profile.BlockedUsersScreen(blockedUsers: []),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/achievement-info':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.AchievementInfoScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/favorites':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Center(child: Text('Favorites not available')),
              );
            }
            return core.MainLayout(
              currentIndex: -1,
              appBar: RouteUtils.createAppBar('Favorites'),
              child: profile.FavoritesScreen(userId: currentUser.uid),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/badges':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: profile.AchievementInfoScreen(),
          ),
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      case '/profile/deep':
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId == null) {
          return RouteUtils.createErrorRoute('No user ID provided');
        }
        return RouteUtils.createMainLayoutRoute(
          child: profile.ProfileViewScreen(userId: userId),
        );

      case core.AppRoutes.profileMenu:
        return RouteUtils.createSimpleRoute(
          child: const profile.ProfileMenuScreen(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Profile feature');
    }
  }
}

class _ProfileActivityWrapper extends StatefulWidget {
  const _ProfileActivityWrapper();

  @override
  State<_ProfileActivityWrapper> createState() => _ProfileActivityWrapperState();
}

class _ProfileActivityWrapperState extends State<_ProfileActivityWrapper>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) => core.MainLayout(
    currentIndex: -1,
    appBar: AppBar(
      title: const Text('Activity History'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Recent Activity', icon: Icon(Icons.timeline)),
          Tab(text: 'Unread', icon: Icon(Icons.notifications)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
      ],
    ),
    child: _ProfileActivityContent(tabController: _tabController),
  );
}

class _ProfileActivityContent extends StatefulWidget {
  const _ProfileActivityContent({required this.tabController});

  final TabController tabController;

  @override
  State<_ProfileActivityContent> createState() => _ProfileActivityContentState();
}

class _ProfileActivityContentState extends State<_ProfileActivityContent> {
  final profile.ProfileActivityService _activityService =
      profile.ProfileActivityService();
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = core.UserService().currentUser;
    setState(() {
      _currentUserId = user?.uid;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: widget.tabController,
      children: [_buildRecentActivityTab(), _buildUnreadTab()],
    );
  }

  Widget _buildRecentActivityTab() =>
      StreamBuilder<List<profile.ProfileActivityModel>>(
        stream: _activityService.streamProfileActivities(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorWidget(
              'Error loading activity',
              snapshot.error.toString(),
            );
          }

          final activities = snapshot.data ?? [];
          if (activities.isEmpty) {
            return _buildEmptyWidget(
              Icons.timeline_outlined,
              'No recent activity',
              'Your recent activity will appear here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) => _buildActivityCard(activities[index]),
          );
        },
      );

  Widget _buildUnreadTab() => StreamBuilder<List<profile.ProfileActivityModel>>(
    stream: _activityService.streamProfileActivities(
      _currentUserId!,
      unreadOnly: true,
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _buildErrorWidget(
          'Error loading unread activities',
          snapshot.error.toString(),
        );
      }

      final unreadActivities = snapshot.data ?? [];
      if (unreadActivities.isEmpty) {
        return _buildEmptyWidget(
          Icons.check_circle_outline,
          'All caught up!',
          'You have no unread activities',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: unreadActivities.length,
        itemBuilder:
            (context, index) =>
                _buildActivityCard(unreadActivities[index], isUnread: true),
      );
    },
  );

  Widget _buildActivityCard(
    profile.ProfileActivityModel activity, {
    bool isUnread = false,
  }) {
    final title = _getActivityTitle(activity);
    final description =
        activity.description ?? _getActivityDescription(activity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnread ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: core.ImageUrlValidator.safeNetworkImage(
            activity.targetUserAvatar,
          ),
          backgroundColor: _getActivityColor(activity.activityType),
          child: activity.targetUserAvatar == null
              ? _getActivityIcon(activity.activityType)
              : null,
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(activity.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: isUnread
            ? const Icon(Icons.fiber_new, color: Colors.blue)
            : null,
        onTap: () => _handleActivityTap(activity),
      ),
    );
  }

  Widget _buildErrorWidget(String title, String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  String _getActivityTitle(profile.ProfileActivityModel activity) {
    final userName = activity.targetUserName ?? 'Someone';
    switch (activity.activityType) {
      case 'profile_view':
        return '$userName viewed your profile';
      case 'follow':
        return '$userName started following you';
      case 'unfollow':
        return '$userName unfollowed you';
      case 'like':
        return '$userName liked your post';
      case 'comment':
        return '$userName commented on your post';
      default:
        return 'Activity: ${activity.activityType}';
    }
  }

  String _getActivityDescription(profile.ProfileActivityModel activity) {
    switch (activity.activityType) {
      case 'profile_view':
        return 'Check out who\'s interested in your profile!';
      case 'follow':
        return 'You gained a new follower!';
      case 'unfollow':
        return 'You lost a follower';
      case 'like':
        return 'Your content is getting appreciation!';
      case 'comment':
        return 'Someone engaged with your content!';
      default:
        return 'Activity occurred';
    }
  }

  Widget _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'like':
        return const Icon(Icons.favorite, color: Colors.white, size: 20);
      case 'comment':
        return const Icon(Icons.chat_bubble, color: Colors.white, size: 20);
      case 'follow':
        return const Icon(Icons.person_add, color: Colors.white, size: 20);
      case 'unfollow':
        return const Icon(Icons.person_remove, color: Colors.white, size: 20);
      case 'profile_view':
        return const Icon(Icons.visibility, color: Colors.white, size: 20);
      default:
        return const Icon(Icons.timeline, color: Colors.white, size: 20);
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'unfollow':
        return Colors.orange;
      case 'profile_view':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _handleActivityTap(profile.ProfileActivityModel activity) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getActivityTitle(activity)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description ?? _getActivityDescription(activity)),
            const SizedBox(height: 16),
            Text(
              'Time: ${_formatTimestamp(activity.createdAt)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...activity.metadata!.entries.map(
                (entry) => Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!activity.isRead)
            TextButton(
              onPressed: () {
                _markAsRead([activity.id]);
                Navigator.pop(context);
              },
              child: const Text('Mark as read'),
            ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(List<String> activityIds) async {
    try {
      await _activityService.markActivitiesAsRead(activityIds);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
