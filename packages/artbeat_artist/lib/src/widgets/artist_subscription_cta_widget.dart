import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Widget for displaying artist subscription call to action
class ArtistSubscriptionCTAWidget extends StatelessWidget {
  final VoidCallback? onSubscribePressed;

  const ArtistSubscriptionCTAWidget({
    super.key,
    this.onSubscribePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withAlpha(25),
                Theme.of(context).primaryColor,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr('art_walk_are_you_an_artist'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tr('art_walk_showcase_your_work_to_local_art_lovers__get_discovered__and_grow_your_career'),
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Feature 1
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.visibility,
                      text: 'Get discovered',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Feature 2
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.store,
                      text: 'Sell your artwork',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Feature 3
                  Expanded(
                    child: _buildFeatureItem(
                      icon: Icons.analytics,
                      text: 'Track analytics',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onSubscribePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  tr('art_walk_start_your_artist_journey'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(230),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
