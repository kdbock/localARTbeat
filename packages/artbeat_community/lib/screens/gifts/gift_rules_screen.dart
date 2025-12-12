import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../theme/community_colors.dart';

class GiftRulesScreen extends StatelessWidget {
  const GiftRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      appBar: const EnhancedUniversalHeader(
        title: 'Gift Guidelines',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const ArtbeatDrawer(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gift Guidelines & Regulations',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSection('Gift Tiers', [
              'Supporter Gift (\$4.99) - Artist featured for 30 days',
              'Fan Gift (\$9.99) - Artist featured for 90 days + 1 artwork featured for 90 days',
              'Patron Gift (\$24.99) - Artist featured for 180 days + 5 artworks featured for 180 days + Artist ad in rotation for 180 days',
              'Benefactor Gift (\$49.99) - Artist featured for 1 year + 5 artworks featured for 1 year + Artist ad in rotation for 1 year',
            ]),
            _buildSection('Rules', [
              'All gifts are non-refundable',
              'Gifts can only be sent to active artists',
              'Maximum of 10 gifts per day per user',
              'Minimum account age of 7 days to send gifts',
              'Recipients must have completed profile verification',
            ]),
            _buildSection('How Gift Credits Work', [
              'Gift recipients receive in-app credits',
              'Credits can be used to purchase subscriptions',
              'Credits can be used to purchase ad products',
              'Credits support artists indirectly through platform engagement',
              'For direct artist support, subscribe to an artist subscription',
            ]),
            _buildSection('Community Guidelines', [
              'No soliciting for gifts',
              'No exchanging gifts for services outside the platform',
              'Respect community guidelines when sending gift messages',
              'Report any suspicious gift activity',
            ]),
            _buildSection('Processing & Security', [
              'All transactions are processed securely through Apple Pay',
              'Gift history is permanently recorded',
              'Suspicious activity is automatically flagged',
              'Gifts are non-refundable per App Store guidelines',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...points.map(
          (point) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(point, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
