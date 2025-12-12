import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class ArtWalkInfoCard extends StatefulWidget {
  final VoidCallback onDismiss;

  const ArtWalkInfoCard({super.key, required this.onDismiss});

  @override
  State<ArtWalkInfoCard> createState() => _ArtWalkInfoCardState();
}

class _ArtWalkInfoCardState extends State<ArtWalkInfoCard> {
  static const String _prefKey = 'art_walk_info_dismissed';
  bool _showCard = true;

  @override
  void initState() {
    super.initState();
    _checkIfShouldShow();
  }

  Future<void> _checkIfShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool(_prefKey) ?? false;

    if (mounted && isDismissed) {
      setState(() => _showCard = false);
      widget.onDismiss();
    }
  }

  Future<void> _dismissForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);

    if (mounted) {
      setState(() => _showCard = false);
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCard) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Welcome to Art Walk!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onDismiss,
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Art Walk lets you discover, document, and share public art around your city.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildFeatureChip('📸 Capture Art'),
                _buildFeatureChip('📍 View on Map'),
                _buildFeatureChip('🚶 Create Routes'),
                _buildFeatureChip('🔍 Explore'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _dismissForever,
                  child: Text(
                    'art_walk_art_walk_info_card_text_dont_show_again'.tr(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.onDismiss,
                  child: Text('art_walk_art_walk_info_card_button_got_it'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
