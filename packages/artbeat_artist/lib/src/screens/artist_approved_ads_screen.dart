import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

class ArtistApprovedAdsScreen extends StatefulWidget {
  const ArtistApprovedAdsScreen({super.key});

  @override
  State<ArtistApprovedAdsScreen> createState() =>
      _ArtistApprovedAdsScreenState();
}

class _ArtistApprovedAdsScreenState extends State<ArtistApprovedAdsScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EnhancedUniversalHeader(
          title: 'Artist Approved Ads',
          showLogo: false,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('art_walk_artist_approved_ads'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.ads_click_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('art_walk_ad_management_coming_soon'),
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('art_walk_manage_your_approved_advertisements_and_promotional_content_here__this_feature_is_currently_under_development'),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr('art_walk_features_coming_soon'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const _FeatureItem(
                    icon: Icons.campaign_outlined,
                    title: 'Ad Campaign Management',
                    description: 'Create and manage your advertising campaigns',
                  ),
                  const _FeatureItem(
                    icon: Icons.analytics_outlined,
                    title: 'Ad Performance Analytics',
                    description: 'Track the performance of your advertisements',
                  ),
                  const _FeatureItem(
                    icon: Icons.approval_outlined,
                    title: 'Approval Status Tracking',
                    description: 'Monitor the approval status of your ads',
                  ),
                  const _FeatureItem(
                    icon: Icons.payment_outlined,
                    title: 'Revenue Tracking',
                    description: 'Track earnings from approved advertisements',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
