import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_community/screens/feed/create_post_screen.dart';
import '../models/public_art_model.dart';
import '../services/instant_discovery_service.dart';
import '../services/social_service.dart';
import '../theme/art_walk_design_system.dart';
import 'package:easy_localization/easy_localization.dart';

/// Modal for capturing discovered art
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

        // Trigger confetti
        _confettiController.play();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 Discovered "${widget.art.title}"!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: ArtWalkDesignSystem.primaryTeal,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Post discovery activity to social feed
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint(
              '🔍 DiscoveryCaptureModal: Posting social activity for discovery',
            );
            await _socialService.postActivity(
              userId: user.uid,
              userName: user.displayName ?? 'Anonymous Explorer',
              userAvatar: user.photoURL,
              type: SocialActivityType.discovery,
              message:
                  'Discovered "${widget.art.title}" by ${widget.art.artistName ?? "Unknown Artist"}!',
              location: widget.userPosition,
              metadata: {
                'artTitle': widget.art.title,
                'artist': widget.art.artistName,
                'discoveryId': discoveryId,
              },
            );
            debugPrint(
              '🔍 DiscoveryCaptureModal: ✅ Social activity posted successfully',
            );
          } else {
            debugPrint(
              '🔍 DiscoveryCaptureModal: ⚠️ No user logged in, skipping social activity',
            );
          }
        } catch (e) {
          // Don't fail the discovery if social posting fails
          debugPrint(
            '🔍 DiscoveryCaptureModal: ❌ Failed to post discovery activity: $e',
          );
        }

        // Close modal after delay
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to save discovery');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_discovery_capture_modal_error_error_capturing_discovery'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to discuss post screen with pre-filled discovery data
  Future<void> _navigateToDiscussPost() async {
    try {
      // Build caption with discovery info
      final caption =
          '📍 Discussing "${widget.art.title}" by ${widget.art.artistName ?? "Unknown Artist"}\n\n';

      debugPrint(
        '🔍 DiscoveryCaptureModal: Navigating to discuss post for "${widget.art.title}"',
      );

      // Close modal first
      if (mounted) {
        Navigator.pop(context);
      }

      // Wait a moment for modal to close, then navigate to create post
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        debugPrint(
          '🔍 DiscoveryCaptureModal: Navigating to CreatePostScreen with pre-filled data:\n'
          'Image: ${widget.art.imageUrl}\n'
          'Caption: $caption',
        );

        // Navigate to CreatePostScreen with pre-filled data from discovery
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => CreatePostScreen(
              prefilledImageUrl: widget.art.imageUrl,
              prefilledCaption: caption,
              isDiscussionPost: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '🔍 DiscoveryCaptureModal: Error navigating to discuss post: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_discovery_capture_modal_error_error_opening_discussion'
                  .tr()
                  .replaceAll('{error}', e.toString()),
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

    return Container(
      decoration: const BoxDecoration(
        color: ArtWalkDesignSystem.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ArtWalkDesignSystem.textSecondary.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Art image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: widget.art.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ArtWalkDesignSystem.primaryTeal.withValues(
                          alpha: 0.1,
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ArtWalkDesignSystem.primaryTeal.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.art.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ArtWalkDesignSystem.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Artist
                if (widget.art.artistName != null)
                  Text(
                    'by ${widget.art.artistName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ArtWalkDesignSystem.textSecondary,
                    ),
                  ),
                const SizedBox(height: 16),

                // Distance and proximity
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isClose
                        ? ArtWalkDesignSystem.accentOrange.withValues(
                            alpha: 0.1,
                          )
                        : ArtWalkDesignSystem.primaryTeal.withValues(
                            alpha: 0.1,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isClose
                          ? ArtWalkDesignSystem.accentOrange
                          : ArtWalkDesignSystem.primaryTeal,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isClose ? Icons.near_me : Icons.navigation,
                        color: isClose
                            ? ArtWalkDesignSystem.accentOrange
                            : ArtWalkDesignSystem.primaryTeal,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.distance.toInt()} meters away',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              proximityMessage,
                              style: TextStyle(
                                color: isClose
                                    ? ArtWalkDesignSystem.accentOrange
                                    : ArtWalkDesignSystem.primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                if (widget.art.description.isNotEmpty) ...[
                  Text(
                    widget.art.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArtWalkDesignSystem.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Art type and tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.art.artType != null)
                      Chip(
                        label: Text(widget.art.artType!),
                        backgroundColor: ArtWalkDesignSystem.primaryTeal
                            .withValues(alpha: 0.1),
                      ),
                    ...widget.art.tags.map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: ArtWalkDesignSystem.accentOrange
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Capture button
                if (!_captured)
                  ElevatedButton(
                    onPressed: isClose && !_isCapturing
                        ? _captureDiscovery
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtWalkDesignSystem.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: ArtWalkDesignSystem.textSecondary
                          .withValues(alpha: 0.3),
                    ),
                    child: _isCapturing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt),
                              const SizedBox(width: 8),
                              Text(
                                isClose
                                    ? 'Capture Discovery'
                                    : 'Get Closer to Capture',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Success message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ArtWalkDesignSystem.primaryTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Discovery Captured!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Discuss button
                      ElevatedButton(
                        onPressed: _navigateToDiscussPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtWalkDesignSystem.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.comment),
                            const SizedBox(width: 8),
                            Text(
                              'Discuss Discovery',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // XP info
                if (!_captured)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      '💎 Earn +20 XP for this discovery!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ArtWalkDesignSystem.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                ArtWalkDesignSystem.primaryTeal,
                ArtWalkDesignSystem.accentOrange,
                ArtWalkDesignSystem.primaryTealLight,
                ArtWalkDesignSystem.accentOrangeLight,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
