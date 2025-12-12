import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/src/theme/artbeat_colors.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

/// Screen that displays all public art captures within 15 miles of user location
class CapturesListScreen extends StatefulWidget {
  const CapturesListScreen({super.key});

  @override
  State<CapturesListScreen> createState() => _CapturesListScreenState();
}

class _CapturesListScreenState extends State<CapturesListScreen> {
  final CaptureService _captureService = CaptureService();
  List<core.CaptureModel> _captures = [];
  bool _isLoading = true;
  String? _error;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get user location
      _userPosition = await _getCurrentPosition();

      // Get all captures
      final allCaptures = await _captureService.getAllCaptures();

      // Filter captures within 15 miles (24.14 km) of user location
      if (_userPosition != null) {
        _captures = allCaptures.where((capture) {
          if (capture.location == null) {
            return false;
          }

          final distance = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            capture.location!.latitude,
            capture.location!.longitude,
          );

          // Convert meters to miles (1 mile = 1609.34 meters)
          final distanceInMiles = distance / 1609.34;
          return distanceInMiles <= 15.0;
        }).toList();
      } else {
        _captures = allCaptures;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'capture_list_error_loading'.tr().replaceAll(
          '{error}',
          e.toString(),
        );
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      // debugPrint('Error getting location: $e');
      return null;
    }
  }

  void _showCaptureDetails(core.CaptureModel capture) {
    Navigator.pushNamed(
      context,
      '/capture/detail',
      arguments: {'captureId': capture.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 2, // Art Walk/Capture tab
      drawer: const CaptureDrawer(),
      appBar: core.EnhancedUniversalHeader(
        title: 'capture_list_title'.tr(),
        showLogo: false,
        showBackButton: true,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  core.ArtbeatColors.primaryPurple,
                ),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ArtbeatColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCaptures,
                    child: Text('admin_admin_settings_text_retry'.tr()),
                  ),
                ],
              ),
            )
          : _captures.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: ArtbeatColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'capture_list_no_captures_nearby'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userPosition != null
                        ? 'capture_list_no_captures_within_range'.tr()
                        : 'capture_list_location_unknown'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: ArtbeatColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCaptures,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _captures.length,
                itemBuilder: (context, index) {
                  final capture = _captures[index];
                  return _buildCaptureCard(capture);
                },
              ),
            ),
    );
  }

  Widget _buildCaptureCard(core.CaptureModel capture) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCaptureDetails(capture),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (capture.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: capture.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capture.title != null && capture.title!.isNotEmpty
                        ? capture.title!
                        : 'Public Art Capture',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  if (capture.locationName != null &&
                      capture.locationName!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: ArtbeatColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            capture.locationName!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  if (capture.description != null &&
                      capture.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      capture.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ArtbeatColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
