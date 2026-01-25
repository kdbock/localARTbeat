import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artist/artbeat_artist.dart';

class BecomeArtistScreen extends StatelessWidget {
  final UserModel user;

  const BecomeArtistScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EnhancedUniversalHeader(
        title: 'become_artist_title'.tr(),
        showLogo: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'become_artist_welcome'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'become_artist_description'.tr(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                context,
                icon: Icons.palette,
                title: 'become_artist_feature_profile_title'.tr(),
                description: 'become_artist_feature_profile_desc'.tr(),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.store,
                title: 'become_artist_feature_gallery_title'.tr(),
                description: 'become_artist_feature_gallery_desc'.tr(),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.analytics,
                title: 'become_artist_feature_analytics_title'.tr(),
                description: 'become_artist_feature_analytics_desc'.tr(),
              ),
              _buildFeatureCard(
                context,
                icon: Icons.event,
                title: 'become_artist_feature_events_title'.tr(),
                description: 'become_artist_feature_events_desc'.tr(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const ArtistOnboardScreen(),
                      ),
                    );
                  },
                  child: Text('become_artist_get_started_button'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
