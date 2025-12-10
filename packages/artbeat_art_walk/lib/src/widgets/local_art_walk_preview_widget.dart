import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

/// Widget to display a preview of local art walks on the dashboard
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Local Art Walks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: widget.onSeeAllPressed,
                child: Text('art_walk_local_art_walk_preview_widget_text_see_all'.tr()),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: _getArtWalksStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                // Art walks stream error: ${snapshot.error}
                return _buildDefaultMapView();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildDefaultMapView();
              }

              // Get coordinates for a representative art walk
              final artWalk = snapshot.data!.docs.first;
              final artWalkData = artWalk.data() as Map<String, dynamic>;

              // Extract coordinates for the map center
              final List<dynamic> artPoints =
                  (artWalkData['artPoints'] as List<dynamic>?) ?? [];

              if (artPoints.isEmpty) {
                return _buildDefaultMapView();
              }

              return _buildMapWithArtWalk(artWalkData, artPoints);
            },
          ),
        ),
      ],
    );
  }

  /// Gets art walks stream with fallback strategy for missing composite index
  Stream<QuerySnapshot> _getArtWalksStream() {
    try {
      // First, try the optimized query that requires composite index
      return FirebaseFirestore.instance
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots();
    } catch (e) {
      // Composite index query failed, falling back to simple query: $e
      // Fallback to a simpler query that doesn't require composite index
      return FirebaseFirestore.instance
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .limit(3)
          .snapshots();
    }
  }

  Widget _buildMapWithArtWalk(
    Map<String, dynamic> artWalkData,
    List<dynamic> artPoints,
  ) {
    // Get coordinates of the first art point for the center
    final firstPoint = artPoints.first as Map<String, dynamic>;
    final lat = firstPoint['latitude'] as double;
    final lng = firstPoint['longitude'] as double;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
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
              ),
            // Overlay to prevent interaction with map
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/art-walk/map'),
                  splashColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Label overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (artWalkData['title'] as String?) ?? 'Art Walk',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${artPoints.length} art pieces • Tap to explore',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setupMarkers(List<dynamic> artPoints) {
    final markers = artPoints.map((point) {
      final Map<String, dynamic> pointData = point as Map<String, dynamic>;
      return Marker(
        markerId: MarkerId(
          (pointData['id'] as String?) ?? DateTime.now().toString(),
        ),
        position: LatLng(
          pointData['latitude'] as double,
          pointData['longitude'] as double,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  Widget _buildDefaultMapView() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/art-walk/map'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.purple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.explore, size: 32, color: Colors.blueGrey),
                SizedBox(height: 6),
                Text(
                  'Local Art Walks',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Explore nearby',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      height: 200,
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Art Walk Preview',
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
