import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Demo screen showcasing the new social engagement system
/// This screen demonstrates all engagement types for different content types
class SocialEngagementDemoScreen extends StatefulWidget {
  const SocialEngagementDemoScreen({super.key});

  @override
  State<SocialEngagementDemoScreen> createState() =>
      _SocialEngagementDemoScreenState();
}

class _SocialEngagementDemoScreenState
    extends State<SocialEngagementDemoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Engagement Demo'),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                    ArtbeatColors.secondaryTeal.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 48,
                    color: ArtbeatColors.primaryPurple,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ARTbeat Social Engagement System',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore different engagement options for various content types',
                    style: TextStyle(
                      fontSize: 16,
                      color: ArtbeatColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Capture Engagement Demo
            _buildContentTypeDemo(
              title: 'Capture Engagement',
              subtitle: 'Street art, murals, and public art discoveries',
              contentType: 'capture',
              icon: Icons.camera_alt,
              color: ArtbeatColors.primaryPurple,
            ),

            const SizedBox(height: 20),

            // Artwork Engagement Demo
            _buildContentTypeDemo(
              title: 'Artwork Engagement',
              subtitle: 'Original artworks and creative pieces',
              contentType: 'artwork',
              icon: Icons.palette,
              color: ArtbeatColors.accentGold,
            ),

            const SizedBox(height: 20),

            // Artist Profile Engagement Demo
            _buildContentTypeDemo(
              title: 'Artist Profile Engagement',
              subtitle: 'Connect with artists and creators',
              contentType: 'artist',
              icon: Icons.person,
              color: ArtbeatColors.primaryGreen,
            ),

            const SizedBox(height: 20),

            // Event Engagement Demo
            _buildContentTypeDemo(
              title: 'Event Engagement',
              subtitle: 'Art exhibitions, workshops, and community events',
              contentType: 'event',
              icon: Icons.event,
              color: ArtbeatColors.secondaryTeal,
            ),

            const SizedBox(height: 20),

            // Post Engagement Demo
            _buildContentTypeDemo(
              title: 'Post Engagement',
              subtitle: 'Community posts and discussions',
              contentType: 'post',
              icon: Icons.article,
              color: ArtbeatColors.accentOrange,
            ),

            const SizedBox(height: 20),

            // Comment Engagement Demo
            _buildContentTypeDemo(
              title: 'Comment Engagement',
              subtitle: 'Engage with comments and replies',
              contentType: 'comment',
              icon: Icons.chat_bubble,
              color: ArtbeatColors.primaryPurple,
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArtbeatColors.backgroundSecondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ArtbeatColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ArtbeatColors.textSecondary,
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This demo showcases the engagement options available for each content type in the ARTbeat platform.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ArtbeatColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeDemo({
    required String title,
    required String subtitle,
    required String contentType,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Engagement Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: ContentEngagementBar(
              contentId: 'demo_${contentType}_id',
              contentType: contentType,
              initialStats: _getDemoStats(),
              showSecondaryActions: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  EngagementStats _getDemoStats() {
    return EngagementStats(
      likeCount: 42,
      commentCount: 15,
      replyCount: 8,
      shareCount: 23,
      seenCount: 156,
      rateCount: 12,
      reviewCount: 5,
      followCount: 89,
      boostCount: 7,
      sponsorCount: 3,
      messageCount: 11,
      commissionCount: 2,
      totalBoostValue: 125.50,
      totalSponsorValue: 450.00,
      lastUpdated: DateTime.now(),
    );
  }
}
