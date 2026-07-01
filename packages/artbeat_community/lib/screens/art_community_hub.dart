import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'feed/enhanced_community_feed_screen.dart';

class ArtCommunityHub extends StatelessWidget {
  const ArtCommunityHub({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedCommunityFeedScreen();
  }
}

class CommunityFeedEmptyState extends StatelessWidget {
  const CommunityFeedEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: ArtbeatColors.primaryPurple,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              'community_feed_empty_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'community_feed_empty_body'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
