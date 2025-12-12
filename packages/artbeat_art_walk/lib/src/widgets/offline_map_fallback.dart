import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';

/// Fallback widget displayed when Google Maps cannot be loaded
///
/// Features:
/// - Shows appropriate error message based on connectivity
/// - Displays cached art pieces count when available offline
/// - Provides retry functionality to reload the map
/// - Offers navigation to art walk list when offline data is available
/// - Visual indicators for offline vs connectivity issues
///
/// Usage:
/// ```dart
/// OfflineMapFallback(
///   onRetry: () => _loadMap(),
///   hasData: _hasCachedData,
///   errorMessage: 'Map loading failed',
///   nearbyArt: _cachedArtPieces,
/// )
/// ```
class OfflineMapFallback extends StatelessWidget {
  /// Callback to retry loading the map
  final VoidCallback onRetry;

  /// Whether cached data is available for offline use
  final bool hasData;

  /// Custom error message to display
  final String errorMessage;

  /// List of nearby art pieces available offline
  final List<PublicArtModel> nearbyArt;

  const OfflineMapFallback({
    super.key,
    required this.onRetry,
    this.hasData = false,
    this.errorMessage = 'Unable to load map',
    this.nearbyArt = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
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
                    Icons.map, // Always show map as the base icon
                    size: 64,
                    color: Colors.grey,
                  ),
                  if (!hasData)
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
            const SizedBox(height: 20),
            Text(
              hasData ? 'Map unavailable while offline' : errorMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasData && nearbyArt.isNotEmpty
                  ? 'You have ${nearbyArt.length} cached art pieces available.\nSome features may be limited in offline mode.'
                  : 'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (hasData && nearbyArt.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/art-walk/list');
                },
                icon: const Icon(Icons.list_alt),
                label: Text(
                  'art_walk_offline_map_fallback_text_view_art_walk_list'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('art_walk_button_try_again'.tr()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
