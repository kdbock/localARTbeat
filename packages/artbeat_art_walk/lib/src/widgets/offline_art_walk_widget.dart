import 'package:flutter/material.dart';

class OfflineArtWalkWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineArtWalkWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Use a stack to create a combined map and offline icon
        SizedBox(
          height: 64,
          width: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.map, // Base map icon
                size: 64,
                color: Colors.grey,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.signal_wifi_off,
                    size: 24,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Map Unavailable',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Unable to load the map. Please check your internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text('art_walk_button_try_again'.tr()),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/art-walk/list');
          },
          child: Text('art_walk_offline_art_walk_widget_text_view_art_walks_list'.tr()),
        ),
      ],
    );
  }
}
