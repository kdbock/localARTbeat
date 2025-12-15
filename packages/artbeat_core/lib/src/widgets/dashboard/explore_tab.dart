import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../artbeat_core.dart' show CaptureModel;

class ExploreTab extends StatelessWidget {
  final LatLng? userLocation;
  final Set<Marker> markers;
  final bool isMapPreviewReady;
  final bool isLoadingCaptures;
  final List<CaptureModel> captures;
  final Widget Function(CaptureModel) buildCaptureCard;
  final VoidCallback onArtWalkTap;

  const ExploreTab({
    Key? key,
    required this.userLocation,
    required this.markers,
    required this.isMapPreviewReady,
    required this.isLoadingCaptures,
    required this.captures,
    required this.buildCaptureCard,
    required this.onArtWalkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Art Walk Preview Section
          GestureDetector(
            onTap: onArtWalkTap,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400] ?? Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isMapPreviewReady && userLocation != null
                    ? Stack(
                        children: [
                          if (kIsWeb)
                            _buildWebMapFallback()
                          else
                            GoogleMap(
                              key: const Key('explore_tab_map'),
                              initialCameraPosition: CameraPosition(
                                target:
                                    userLocation ??
                                    const LatLng(35.7796, -78.6382),
                                zoom: 14,
                              ),
                              markers: markers,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              rotateGesturesEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              liteModeEnabled: true,
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explore Art Walk',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${markers.length} artworks nearby',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Captured Art',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: isLoadingCaptures
                ? const Center(child: CircularProgressIndicator())
                : captures.isEmpty
                ? Center(child: Text('dashboard_no_captures_found'.tr()))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: captures.length,
                    itemBuilder: (c, i) => buildCaptureCard(captures[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Explore Map',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Map preview available on mobile',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
