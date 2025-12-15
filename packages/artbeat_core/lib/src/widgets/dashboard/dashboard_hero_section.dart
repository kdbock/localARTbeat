import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DashboardHeroSection extends StatefulWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onFindArtTap;

  const DashboardHeroSection({
    Key? key,
    required this.viewModel,
    required this.onFindArtTap,
  }) : super(key: key);

  @override
  State<DashboardHeroSection> createState() => _DashboardHeroSectionState();
}

class _DashboardHeroSectionState extends State<DashboardHeroSection> {
  static const String _mapKey = 'dashboard_hero_map';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(gradient: ArtbeatColors.primaryGradient),
      child: Stack(
        children: [
          // Map background
          Positioned.fill(
            child: ClipRRect(
              child: widget.viewModel.isLoadingLocation
                  ? Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                    )
                  : kIsWeb
                  ? _buildWebMapFallback()
                  : GoogleMap(
                      key: const Key(_mapKey),
                      initialCameraPosition: CameraPosition(
                        target:
                            widget.viewModel.mapLocation ??
                            const LatLng(35.7796, -78.6382),
                        zoom: 14.0,
                      ),
                      markers: widget.viewModel.markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      style: '''[
                            {
                              "featureType": "poi",
                              "elementType": "labels",
                              "stylers": [{"visibility": "off"}]
                            },
                            {
                              "featureType": "transit",
                              "elementType": "labels",
                              "stylers": [{"visibility": "off"}]
                            },
                            {
                              "featureType": "road",
                              "elementType": "labels",
                              "stylers": [{"visibility": "off"}]
                            }
                          ]''',
                      onMapCreated: widget.viewModel.onMapCreated,
                      compassEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
            ),
          ),

          // Loading overlay
          if (widget.viewModel.isLoadingMap)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'dashboard_hero_loading_location'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.7),
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Tagline overlay
          Positioned(bottom: 24, left: 24, right: 24, child: _buildTagline()),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard_hero_tagline'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'dashboard_hero_subtitle'.tr(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _buildFindArtButton(),
      ],
    );
  }

  Widget _buildFindArtButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onFindArtTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'dashboard_hero_find_art'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'dashboard_hero_interactive_map'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'dashboard_hero_mobile_only'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
