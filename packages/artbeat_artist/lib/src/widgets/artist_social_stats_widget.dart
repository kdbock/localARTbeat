import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/subscription_service.dart' as artist_subscription;
import 'package:google_fonts/google_fonts.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  label: 'artist_artist_public_profile_stat_followers',
                  value: '$totalFollowers',
                  color: const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  label: 'artist_artist_public_profile_stat_total_engagement',
                  value: '$totalEngagement',
                  color: const Color(0xFFFF3D8D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  label: 'artist_artist_public_profile_stat_avg_engagement',
                  value: '$avgEngagement',
                  color: const Color(0xFF7C4DFF),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: 10),
          Expanded(child: _buildShimmerCard()),
          const SizedBox(width: 10),
          Expanded(child: _buildShimmerCard()),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }
}
