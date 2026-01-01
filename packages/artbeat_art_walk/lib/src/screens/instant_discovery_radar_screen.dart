import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/widgets/instant_discovery_radar.dart';
import 'package:artbeat_art_walk/src/widgets/discovery_capture_modal.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

/// Refactored full-screen Instant Discovery Radar with design guide
class InstantDiscoveryRadarScreen extends StatefulWidget {
  final Position? userPosition;
  final List<PublicArtModel>? initialNearbyArt;

  const InstantDiscoveryRadarScreen({
    super.key,
    this.userPosition,
    this.initialNearbyArt,
  });

  @override
  State<InstantDiscoveryRadarScreen> createState() =>
      _InstantDiscoveryRadarScreenState();
}

class _InstantDiscoveryRadarScreenState
    extends State<InstantDiscoveryRadarScreen> {
  late List<PublicArtModel> _nearbyArt;
  // bool _hasDiscoveries = false;
  Position? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nearbyArt = widget.initialNearbyArt ?? [];
    _userPosition = widget.userPosition;
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_userPosition == null) {
      try {
        _userPosition = await Geolocator.getCurrentPosition();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_instant_discovery_radar_text_location_error'.tr(),
              ),
            ),
          );
          Navigator.pop(context);
          return;
        }
      }
    }

    if (_nearbyArt.isEmpty && _userPosition != null) {
      // Would load from discovery service
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleArtTap(PublicArtModel art, double distance) async {
    if (_userPosition == null) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => DiscoveryCaptureModal(
          art: art,
          distance: distance,
          userPosition: _userPosition!,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _nearbyArt.removeWhere((a) => a.id == art.id);
      });

      if (_nearbyArt.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_instant_discovery_radar_text_you_discovered_all'.tr(),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WorldBackground(
      child: SafeArea(
        child: InstantDiscoveryRadar(
          userPosition: _userPosition!,
          nearbyArt: _nearbyArt,
          radiusMeters: 500,
          onArtTap: _handleArtTap,
        ),
      ),
    );
  }
}
