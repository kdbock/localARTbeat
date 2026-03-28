// Refactored DiscoveryCaptureModal to match Local ARTbeat design_guide.md

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:artbeat_core/artbeat_core.dart'
    hide PublicArtModel, SocialActivityType;
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/services/instant_discovery_service.dart';
import 'package:artbeat_art_walk/src/services/social_service.dart';
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
  late final InstantDiscoveryService _discoveryService;
  late final SocialService _socialService;
  late final UserService _userService;
  late ConfettiController _confettiController;
  bool _isCapturing = false;
  bool _captured = false;
  String? _feedbackMessage;
  Color? _feedbackColor;
  PublicArtModel? _enrichedArt;

  // Simple static cache for user info
  static final Map<String, UserModel> _userCache = {};

  @override
  void initState() {
    super.initState();
    _discoveryService = context.read<InstantDiscoveryService>();
    _socialService = context.read<SocialService>();
    _userService = context.read<UserService>();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _enrichArtWithUserInfo();
  }

  Future<void> _enrichArtWithUserInfo() async {
    final art = widget.art;

    // If already has user info, no need to fetch
    if (art.userName != null && art.userHandle != null) {
      return;
    }

    // Check cache first
    if (_userCache.containsKey(art.userId)) {
      if (mounted) {
        setState(() {
          _enrichedArt = art.copyWith(
            userName: _userCache[art.userId]!.fullName,
            userHandle: _userCache[art.userId]!.username,
            userProfileUrl: _userCache[art.userId]!.profileImageUrl,
          );
        });
      }
      return;
    }

    try {
      final userModel = await _userService.getUserById(art.userId);
      if (userModel != null) {
        _userCache[art.userId] = userModel;
        if (mounted) {
          setState(() {
            _enrichedArt = art.copyWith(
              userName: userModel.fullName,
              userHandle: userModel.username,
              userProfileUrl: userModel.profileImageUrl,
            );
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error enriching art with user info: $e');
    }
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
          _feedbackMessage = 'discovery_success_message'.tr(
            namedArgs: {'title': widget.art.title},
          );
          _feedbackColor = const Color(0xFF22D3EE);
        });

        _confettiController.play();

        final user = _userService.currentUser;
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

        await Future<void>.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save discovery');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _feedbackMessage = 'discovery_error_message'.tr(
            namedArgs: {'error': e.toString()},
          );
          _feedbackColor = Colors.red;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proximityMessage = _discoveryService.getProximityMessage(
      widget.distance,
    );
    final isClose = widget.distance < 50;
    final artImageUrl = ImageUrlValidator.normalizeImageUrl(
      widget.art.imageUrl,
    );
    final hasValidArtImage = ImageUrlValidator.isValidImageUrl(artImageUrl);
    final profileImageProvider = ImageUrlValidator.safeNetworkImage(
      _enrichedArt?.userProfileUrl ?? widget.art.userProfileUrl,
    );

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasValidArtImage)
                CachedNetworkImage(
                  imageUrl: artImageUrl!,
                  memCacheHeight: 400,
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
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 36,
                  ),
                ),
              const SizedBox(height: 16),
              // User Attribution and Date
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.white54,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _enrichedArt?.userName ??
                          widget.art.userName ??
                          'Art Enthusiast',
                      style: AppTypography.body(
                        Colors.white70,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeago.format(widget.art.createdAt),
                    style: AppTypography.body(
                      Colors.white38,
                    ).copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
              if (_feedbackMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _feedbackMessage!,
                    style: AppTypography.body(_feedbackColor!),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              // Sponsor Banner
              SponsorBanner(
                placementKey: SponsorshipPlacements.captureDetailBanner,
                userLocation: LatLng(
                  widget.userPosition.latitude,
                  widget.userPosition.longitude,
                ),
                padding: EdgeInsets.zero,
                showPlaceholder: true,
                onPlaceholderTap: () =>
                    Navigator.pushNamed(context, '/capture-sponsorship'),
              ),
              const SizedBox(height: 24),
              if (!_captured)
                GradientCTAButton(
                  label: _isCapturing
                      ? 'capturing'.tr()
                      : (isClose
                            ? 'capture_discovery'.tr()
                            : 'get_closer'.tr()),
                  icon: _isCapturing ? null : Icons.camera_alt,
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
