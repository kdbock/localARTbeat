// Refactored DiscoveryCaptureModal to match Local ARTbeat design_guide.md

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

// import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/services/instant_discovery_service.dart';
import 'package:artbeat_art_walk/src/services/social_service.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/gradient_cta_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';

class DiscoveryCaptureModal extends StatefulWidget {
  final PublicArtModel art;
  final double distance;
  final Position userPosition;

  const DiscoveryCaptureModal({
    super.key,
    required this.art,
    required this.distance,
    required this.userPosition,
  });

  @override
  State<DiscoveryCaptureModal> createState() => _DiscoveryCaptureModalState();
}

class _DiscoveryCaptureModalState extends State<DiscoveryCaptureModal> {
  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();
  final SocialService _socialService = SocialService();
  late ConfettiController _confettiController;
  bool _isCapturing = false;
  bool _captured = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _captureDiscovery() async {
    if (_isCapturing || _captured) return;

    setState(() => _isCapturing = true);

    try {
      final discoveryId = await _discoveryService.saveDiscovery(
        widget.art,
        widget.userPosition,
      );

      if (discoveryId != null && mounted) {
        setState(() {
          _captured = true;
          _isCapturing = false;
        });

        _confettiController.play();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'discovery_success_message'.tr(
                      namedArgs: {'title': widget.art.title},
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF22D3EE),
            duration: const Duration(seconds: 3),
          ),
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _socialService.postActivity(
            userId: user.uid,
            userName: user.displayName ?? 'Anonymous Explorer',
            userAvatar: user.photoURL,
            type: SocialActivityType.discovery,
            message: 'discovery_feed_message'.tr(
              namedArgs: {
                'title': widget.art.title,
                'artist': widget.art.artistName ?? "Unknown Artist",
              },
            ),
            location: widget.userPosition,
            metadata: {
              'artTitle': widget.art.title,
              'artist': widget.art.artistName,
              'discoveryId': discoveryId,
            },
          );
        }

        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save discovery');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'discovery_error_message'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximityMessage = _discoveryService.getProximityMessage(
      widget.distance,
    );
    final isClose = widget.distance < 50;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CachedNetworkImage(
                imageUrl: widget.art.imageUrl,
                imageBuilder: (context, imageProvider) => Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
              const SizedBox(height: 16),
              Text(widget.art.title, style: AppTypography.screenTitle()),
              if (widget.art.artistName != null)
                Text(
                  'by ${widget.art.artistName}',
                  style: AppTypography.body(Colors.white70),
                ),
              const SizedBox(height: 16),
              Text(
                proximityMessage,
                style: AppTypography.helper(
                  isClose ? Colors.amber : Colors.teal,
                ),
              ),
              const SizedBox(height: 24),
              if (!_captured)
                GradientCTAButton(
                  label: isClose ? 'capture_discovery'.tr() : 'get_closer'.tr(),
                  icon: Icons.camera_alt,
                  onPressed: isClose && !_isCapturing
                      ? () {
                          _captureDiscovery();
                        }
                      : null,
                ),
              if (_captured)
                Text(
                  'discovery_success_cta'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(Colors.tealAccent),
                ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                Color(0xFF22D3EE),
                Color(0xFFFFC857),
                Color(0xFF7C4DFF),
                Color(0xFF34D399),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
