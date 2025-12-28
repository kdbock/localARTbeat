import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/services/social_service.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';

/// Widget for displaying a feed of social activities
class SocialActivityFeed extends StatefulWidget {
  final Position? userPosition;
  final int maxItems;

  const SocialActivityFeed({super.key, this.userPosition, this.maxItems = 5});

  @override
  State<SocialActivityFeed> createState() => _SocialActivityFeedState();
}

class _SocialActivityFeedState extends State<SocialActivityFeed> {
  final SocialService _socialService = SocialService();
  List<SocialActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void didUpdateWidget(SocialActivityFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userPosition != oldWidget.userPosition) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    if (widget.userPosition == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final activities = await _socialService.getNearbyActivities(
        userPosition: widget.userPosition!,
        limit: widget.maxItems,
      );

      // If we have activities, use them
      if (activities.isNotEmpty) {
        if (mounted) {
          setState(() {
            _activities = activities;
            _isLoading = false;
          });
        }
        return;
      }

      // If no nearby activities, try to get the current user's own activities
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userActivities = await _socialService.getFriendsActivities(
            friendIds: [user.uid],
            limit: widget.maxItems,
          );
          if (mounted) {
            setState(() {
              _activities = userActivities;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } catch (e) {
        AppLogger.error('Error loading user activities', error: e);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      AppLogger.error('Error loading social activities', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getActivityIcon(SocialActivityType type) {
    switch (type) {
      case SocialActivityType.discovery:
        return '🎨';
      case SocialActivityType.capture:
        return '📸';
      case SocialActivityType.walkCompleted:
        return '🚶';
      case SocialActivityType.achievement:
        return '🏆';
      case SocialActivityType.friendJoined:
        return '👋';
      case SocialActivityType.milestone:
        return '⭐';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ArtWalkDesignSystem.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.2),
          ),
        ),
        child: const Column(
          children: [
            Text(
              '🌟 Be the first to discover art in your area!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ArtWalkDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ArtWalkDesignSystem.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArtWalkDesignSystem.primaryTeal.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: ArtWalkDesignSystem.primaryTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Activity Feed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ArtWalkDesignSystem.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._activities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(SocialActivity activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _getActivityIcon(activity.type),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Activity content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name and time
                Row(
                  children: [
                    Text(
                      activity.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ArtWalkDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(activity.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ArtWalkDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Activity message
                Text(
                  activity.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ArtWalkDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
