import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/gradient_cta_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:artbeat_art_walk/src/widgets/world_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocalArtWalkPreviewWidget extends StatefulWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const LocalArtWalkPreviewWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  State<LocalArtWalkPreviewWidget> createState() =>
      _LocalArtWalkPreviewWidgetState();
}

class _LocalArtWalkPreviewWidgetState extends State<LocalArtWalkPreviewWidget> {
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final zipBadge = widget.zipCode.isNotEmpty
        ? 'art_walk_art_walk_card_text_zip'.tr(
            namedArgs: {'zip': widget.zipCode},
          )
        : null;

    return WorldBackground(
      withBlobs: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'art_walk_local_art_walk_preview_widget_title'.tr(),
                          style: AppTypography.screenTitle(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'art_walk_local_art_walk_preview_widget_subtitle'
                              .tr(),
                          style: AppTypography.body(
                            Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (zipBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(zipBadge, style: AppTypography.badge()),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              AspectRatio(aspectRatio: 16 / 9, child: _buildMapCard()),
              const SizedBox(height: 20),
              if (widget.onSeeAllPressed != null)
                GradientCTAButton(
                  label: 'art_walk_local_art_walk_preview_widget_cta'.tr(),
                  icon: Icons.explore,
                  onPressed: widget.onSeeAllPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getArtWalksStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _wrapMapSurface(_buildLoadingState());
        }

        if (snapshot.hasError) {
          return _wrapMapSurface(_buildDefaultMapView());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _wrapMapSurface(_buildDefaultMapView());
        }

        final artWalk = snapshot.data!.docs.first;
        final artWalkData = artWalk.data() as Map<String, dynamic>;
        final List<dynamic> artPoints =
            (artWalkData['artPoints'] as List<dynamic>?) ?? [];

        if (artPoints.isEmpty) {
          return _wrapMapSurface(_buildDefaultMapView());
        }

        return _wrapMapSurface(_buildMapWithArtWalk(artWalkData, artPoints));
      },
    );
  }

  Widget _wrapMapSurface(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
    );
  }

  Widget _buildMapWithArtWalk(
    Map<String, dynamic> artWalkData,
    List<dynamic> artPoints,
  ) {
    final firstPoint = artPoints.first as Map<String, dynamic>;
    final lat = (firstPoint['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (firstPoint['longitude'] as num?)?.toDouble() ?? 0.0;

    final artPiecesLabel = 'art_walk_local_art_walk_preview_widget_overlay_meta'
        .tr(namedArgs: {'count': artPoints.length.toString()});

    return Stack(
      children: [
        if (kIsWeb)
          _buildWebMapFallback()
        else
          GoogleMap(
            key: const Key('art_walk_preview_map'),
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _setupMarkers(artPoints);
            },
            markers: _markers,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            myLocationButtonEnabled: false,
            buildingsEnabled: true,
          ),
        Positioned.fill(
          child: Semantics(
            label: 'art_walk_local_art_walk_preview_widget_text_map_hint'.tr(),
            button: true,
            child: GestureDetector(
              onTap: _openMap,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withValues(alpha: 0.6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (artWalkData['title'] as String?) ??
                      'art_walk_local_art_walk_preview_widget_title'.tr(),
                  style: AppTypography.body(),
                ),
                const SizedBox(height: 8),
                Text(artPiecesLabel, style: AppTypography.helper()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF0B0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'art_walk_local_art_walk_preview_widget_text_loading'.tr(),
              style: AppTypography.body(Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultMapView() {
    return GestureDetector(
      onTap: _openMap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1B33), Color(0xFF0D2B3F)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 12),
              Text(
                'art_walk_local_art_walk_preview_widget_text_empty_title'.tr(),
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
              const SizedBox(height: 8),
              Text(
                'art_walk_local_art_walk_preview_widget_text_empty_description'
                    .tr(),
                textAlign: TextAlign.center,
                style: AppTypography.helper(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebMapFallback() {
    return Container(
      color: const Color(0xFF0B0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 12),
            Text(
              'art_walk_local_art_walk_preview_widget_text_web_title'.tr(),
              style: AppTypography.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_local_art_walk_preview_widget_text_web_description'
                  .tr(),
              style: AppTypography.helper(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getArtWalksStream() {
    try {
      return FirebaseFirestore.instance
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots();
    } catch (_) {
      return FirebaseFirestore.instance
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .limit(3)
          .snapshots();
    }
  }

  void _setupMarkers(List<dynamic> artPoints) {
    final markers = artPoints.map((point) {
      final Map<String, dynamic> pointData = point as Map<String, dynamic>;
      return Marker(
        markerId: MarkerId(
          (pointData['id'] as String?) ?? DateTime.now().toString(),
        ),
        position: LatLng(
          (pointData['latitude'] as num?)?.toDouble() ?? 0.0,
          (pointData['longitude'] as num?)?.toDouble() ?? 0.0,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  void _openMap() {
    Navigator.pushNamed(context, '/art-walk/map');
  }
}
