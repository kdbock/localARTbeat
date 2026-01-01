import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_core/shared_widgets.dart';

/// Activity card that matches the style of EnhancedPostCard
class ActivityCard extends StatelessWidget {
  final art_walk.SocialActivity activity;
  final VoidCallback? onTap;

  const ActivityCard({super.key, required this.activity, this.onTap});

  String _getActivityIcon(art_walk.SocialActivityType type) {
    switch (type) {
      case art_walk.SocialActivityType.discovery:
        return '🎨';
      case art_walk.SocialActivityType.capture:
        return '📸';
      case art_walk.SocialActivityType.walkCompleted:
        return '🚶';
      case art_walk.SocialActivityType.achievement:
        return '🏆';
      case art_walk.SocialActivityType.friendJoined:
        return '👋';
      case art_walk.SocialActivityType.milestone:
        return '⭐';
    }
  }

  String _getActivityTitle(art_walk.SocialActivityType type) {
    switch (type) {
      case art_walk.SocialActivityType.discovery:
        return 'activity_discovery_title'.tr();
      case art_walk.SocialActivityType.capture:
        return 'activity_capture_title'.tr();
      case art_walk.SocialActivityType.walkCompleted:
        return 'activity_walk_completed_title'.tr();
      case art_walk.SocialActivityType.achievement:
        return 'activity_achievement_title'.tr();
      case art_walk.SocialActivityType.friendJoined:
        return 'activity_friend_joined_title'.tr();
      case art_walk.SocialActivityType.milestone:
        return 'activity_milestone_title'.tr();
    }
  }

  Color _getActivityColor(art_walk.SocialActivityType type) {
    switch (type) {
      case art_walk.SocialActivityType.discovery:
        return ArtbeatColors.primaryPurple;
      case art_walk.SocialActivityType.capture:
        return ArtbeatColors.primaryGreen;
      case art_walk.SocialActivityType.walkCompleted:
        return const Color(0xFF4CAF50); // Green for completion
      case art_walk.SocialActivityType.achievement:
        return const Color(0xFFFFD700); // Gold for achievements
      case art_walk.SocialActivityType.friendJoined:
        return ArtbeatColors.primaryPurple;
      case art_walk.SocialActivityType.milestone:
        return const Color(0xFFFFA500); // Orange for milestones
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityColor = _getActivityColor(activity.type);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with activity icon and type
            _buildHeader(activityColor),

            // Activity message
            _buildContent(),

            // Location if available
            if (activity.location != null) _buildLocation(),

            // Timestamp
            _buildTimestamp(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color activityColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Activity icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _getActivityIcon(activity.type),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16), // multiple of 8
          // Activity title and user
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityTitle(activity.type),
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: activityColor,
                  ),
                ),
                Text(
                  activity.userName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7), // secondary
                  ),
                ),
              ],
            ),
          ),

          // Activity type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              activity.type.name.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                color: activityColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // adjust to multiple of 8
      child: Text(
        activity.message,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: Colors.white.withValues(alpha: 0.92), // primary text
        ),
      ),
    );
  }

  Widget _buildLocation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: Colors.white.withValues(alpha: 0.45), // tertiary
          ),
          const SizedBox(width: 8),
          Text(
            'activity_nearby'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        timeago.format(activity.timestamp),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
