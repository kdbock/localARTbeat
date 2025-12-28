// lib/src/widgets/social_activity_feed.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/services/social_service.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';

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

      if (activities.isNotEmpty) {
        if (mounted) {
          setState(() {
            _activities = activities;
            _isLoading = false;
          });
        }
        return;
      }

      // Fallback to user's own activities
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
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Error loading activities', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getActivityEmoji(SocialActivityType type) {
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
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'social_feed_empty'.tr(), // Add key to translation JSON
              style: AppTypography.body(Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            ..._activities.map(_buildActivityItem).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF22D3EE).withValues(
                red: 34.0,
                green: 211.0,
                blue: 238.0,
                alpha: (0.1 * 255),
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.timeline,
              color: Color(0xFF22D3EE),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'social_feed_title'.tr(), // Add key to translation
              style: AppTypography.screenTitle(),
            ),
          ),
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
          // Emoji icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withValues(
                red: 255.0,
                green: 255.0,
                blue: 255.0,
                alpha: (0.08 * 255),
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                _getActivityEmoji(activity.type),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + time
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        activity.userName,
                        style: AppTypography.body(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(activity.timestamp),
                      style: AppTypography.helper(Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.message,
                  style: AppTypography.body(
                    const Color(0xFFFFFFFF).withValues(
                      red: 255.0,
                      green: 255.0,
                      blue: 255.0,
                      alpha: (0.7 * 255),
                    ),
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
