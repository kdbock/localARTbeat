import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/profile_activity_model.dart';
import '../services/profile_activity_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileActivityScreen extends StatefulWidget {
  const ProfileActivityScreen({super.key});

  @override
  State<ProfileActivityScreen> createState() => _ProfileActivityScreenState();
}

class _ProfileActivityScreenState extends State<ProfileActivityScreen>
    with SingleTickerProviderStateMixin {
  final ProfileActivityService _activityService = ProfileActivityService();
  late TabController _tabController;

  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    final user = Provider.of<UserService>(context, listen: false).currentUser;
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
      controller: _tabController,
      children: [_buildRecentActivityTab(), _buildUnreadTab()],
    );
  }

  Widget _buildRecentActivityTab() {
    return StreamBuilder<List<ProfileActivityModel>>(
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
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity);
          },
        );
      },
    );
  }

  Widget _buildUnreadTab() {
    return StreamBuilder<List<ProfileActivityModel>>(
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
          itemBuilder: (context, index) {
            final activity = unreadActivities[index];
            return _buildActivityCard(activity, isUnread: true);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(
    ProfileActivityModel activity, {
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
          backgroundImage: ImageUrlValidator.safeNetworkImage(
            activity.targetUserAvatar,
          ),
          backgroundColor: _getActivityColor(activity.activityType),
          child: !ImageUrlValidator.isValidImageUrl(activity.targetUserAvatar)
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

  Widget _buildErrorWidget(String title, String error) {
    return Center(
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
  }

  Widget _buildEmptyWidget(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getActivityTitle(ProfileActivityModel activity) {
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

  String _getActivityDescription(ProfileActivityModel activity) {
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
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleActivityTap(ProfileActivityModel activity) {
    // Show activity details or navigate based on type
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
            child: Text('profile_activity_close'.tr()),
          ),
          if (!activity.isRead)
            TextButton(
              onPressed: () {
                _markAsRead([activity.id]);
                Navigator.pop(context);
              },
              child: Text('profile_activity_mark_read'.tr()),
            ),
        ],
      ),
    );
  }

  void _markAsRead(List<String> activityIds) async {
    try {
      await _activityService.markActivitiesAsRead(activityIds);
    } catch (e) {
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
