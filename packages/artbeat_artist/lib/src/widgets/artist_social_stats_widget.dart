import 'package:flutter/material.dart';
import '../services/subscription_service.dart' as artist_subscription;

/// Widget that displays artist social statistics
class ArtistSocialStatsWidget extends StatefulWidget {
  final String artistProfileId;
  final int? followerCount;

  const ArtistSocialStatsWidget({
    super.key,
    required this.artistProfileId,
    this.followerCount,
  });

  @override
  State<ArtistSocialStatsWidget> createState() =>
      _ArtistSocialStatsWidgetState();
}

class _ArtistSocialStatsWidgetState extends State<ArtistSocialStatsWidget> {
  final artist_subscription.SubscriptionService _subscriptionService =
      artist_subscription.SubscriptionService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _subscriptionService.getFollowerStats(
      artistProfileId: widget.artistProfileId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data ?? {};
        final totalFollowers = (stats['totalFollowers'] as int?) ?? 0;
        final totalEngagement = (stats['totalEngagement'] as int?) ?? 0;
        final avgEngagement = (stats['averageEngagement'] as int?) ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                icon: Icons.people,
                label: 'Followers',
                value: '$totalFollowers',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.favorite,
                label: 'Total Engagement',
                value: '$totalEngagement',
                color: Colors.red,
              ),
              _buildStatCard(
                icon: Icons.trending_up,
                label: 'Avg Engagement',
                value: '$avgEngagement',
                color: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildShimmerCard(),
          _buildShimmerCard(),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
