// Refactored DiscoveryCaptureModal to match Local ARTbeat design_guide.md

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:artbeat_core/artbeat_core.dart'
    hide PublicArtModel, SocialActivityType;
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/constants/routes.dart';
import 'package:artbeat_art_walk/src/services/go_now_flow_service.dart';
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
  final GoNowFlowService _goNowFlow = GoNowFlowService();
  final ImagePicker _imagePicker = ImagePicker();

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
    _goNowFlow.trackFunnelEvent('detail_open', <String, Object?>{
      'pieceId': widget.art.id,
      'source': 'radar',
    });
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
        final selfieUrl = await _promptAndUploadArtFlexSelfie();

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
              if (selfieUrl != null) 'photoUrl': selfieUrl,
              if (selfieUrl != null) 'selfieUrl': selfieUrl,
              if (selfieUrl != null) 'source': 'artflex_discovery_selfie',
            },
          );
        }
        _goNowFlow.setStatus(widget.art.id, GoNowStatus.captured);
        _goNowFlow.trackFunnelEvent('capture_completed', <String, Object?>{
          'pieceId': widget.art.id,
          'source': 'radar',
        });

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

  Future<String?> _promptAndUploadArtFlexSelfie() async {
    final shouldPrompt = await _shouldPromptForDiscoveryArtFlex();
    if (!shouldPrompt) {
      return null;
    }
    if (!mounted) {
      return null;
    }

    bool dontAskAgain = false;
    final shouldTakeSelfie = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a selfie with this art?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Optional: share an ARTflex selfie to the social feed for this discovery.',
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: dontAskAgain,
                onChanged: (value) => setDialogState(() {
                  dontAskAgain = value ?? false;
                }),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Don't ask again"),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add Selfie'),
            ),
          ],
        ),
      ),
    );

    if (dontAskAgain) {
      await _setDiscoveryArtFlexPromptEnabled(false);
    }

    if (shouldTakeSelfie != true) {
      return null;
    }

    final selfie = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (selfie == null) {
      return null;
    }

    try {
      final user = _userService.currentUser;
      if (user == null) {
        return null;
      }

      final selfieBytes = await selfie.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final selfiePath = 'community/artflex/${user.uid}_$timestamp.jpg';
      final selfieRef = FirebaseStorage.instance.ref().child(selfiePath);

      await selfieRef.putData(
        selfieBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await selfieRef.getDownloadURL();
    } catch (e) {
      AppLogger.warning('Optional discovery ARTflex selfie upload failed: $e');
      return null;
    }
  }

  Future<bool> _shouldPromptForDiscoveryArtFlex() async {
    try {
      final user = _userService.currentUser;
      if (user == null) {
        return true;
      }

      final doc = await FirebaseFirestore.instance
          .collection('userSettings')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final social = data?['social'];
      if (social is Map<String, dynamic>) {
        final enabled = social['promptDiscoveryArtFlex'];
        if (enabled is bool) {
          return enabled;
        }
      }
      return true;
    } catch (e) {
      AppLogger.warning(
        'Failed reading discovery ARTflex prompt setting, defaulting enabled: $e',
      );
      return true;
    }
  }

  Future<void> _setDiscoveryArtFlexPromptEnabled(bool enabled) async {
    try {
      final user = _userService.currentUser;
      if (user == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('userSettings')
          .doc(user.uid)
          .set({
            'social': {'promptDiscoveryArtFlex': enabled},
          }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.warning('Failed writing discovery ARTflex prompt setting: $e');
    }
  }

  Future<void> _goNowToArt() async {
    _goNowFlow.trackFunnelEvent('go_now_tap', <String, Object?>{
      'pieceId': widget.art.id,
      'source': 'radar',
    });
    _goNowFlow.setStatus(widget.art.id, GoNowStatus.enRoute);

    final result = await Navigator.pushNamed(
      context,
      ArtWalkRoutes.goNowNavigation,
      arguments: <String, dynamic>{
        'pieceId': widget.art.id,
        'title': widget.art.title,
        'latitude': widget.art.location.latitude,
        'longitude': widget.art.location.longitude,
        'source': 'radar',
        'showAddToWalkAction': true,
      },
    );

    if (!mounted) return;

    if (result == 'arrived_capture' || result == 'arrived_add_to_walk') {
      _goNowFlow.setStatus(widget.art.id, GoNowStatus.arrived);
      setState(() {
        _feedbackMessage = result == 'arrived_add_to_walk'
            ? "Added to your walk queue. Capture when ready."
            : "You're here. Capture now or keep exploring.";
        _feedbackColor = Colors.tealAccent;
      });
      return;
    }

    if (result == 'skipped') {
      _goNowFlow.setStatus(widget.art.id, GoNowStatus.skipped);
    }
  }

  Future<void> _handlePrimaryGoNowAction(bool isClose) async {
    if (isClose) {
      await _captureDiscovery();
      return;
    }
    await _goNowToArt();
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
    final goNowStatus = _goNowFlow.statusFor(widget.art.id);
    final goNowLabel = isClose
        ? "You're Here - Capture"
        : switch (goNowStatus) {
            GoNowStatus.enRoute => 'Resume Route',
            GoNowStatus.arrived => "You're Here - Capture",
            GoNowStatus.captured => 'Captured',
            _ => 'Go Now',
          };

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
              GradientCTAButton(
                label: goNowLabel,
                icon: Icons.near_me,
                onPressed: _captured
                    ? null
                    : () {
                        _handlePrimaryGoNowAction(isClose);
                      },
              ),
              const SizedBox(height: 12),
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
