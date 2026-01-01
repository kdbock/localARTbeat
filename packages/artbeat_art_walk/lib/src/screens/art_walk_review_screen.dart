import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;
import 'package:artbeat_art_walk/src/models/models.dart';
import 'package:artbeat_art_walk/src/constants/routes.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:artbeat_art_walk/src/widgets/widgets.dart';

/// Review screen shown after creating an art walk, allows selfie upload before starting
class ArtWalkReviewScreen extends StatefulWidget {
  static const String routeName = '/art-walk/review';

  final String artWalkId;
  final ArtWalkModel artWalk;

  const ArtWalkReviewScreen({
    super.key,
    required this.artWalkId,
    required this.artWalk,
  });

  @override
  State<ArtWalkReviewScreen> createState() => _ArtWalkReviewScreenState();
}

class _ArtWalkReviewScreenState extends State<ArtWalkReviewScreen> {
  late final ArtWalkService _artWalkService;
  File? _selfieFile;
  String _startingLocation = 'Current Location';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _artWalkService = context.read<ArtWalkService>();
    _getCurrentLocationName();
  }

  Future<void> _getCurrentLocationName() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final city = placemark.locality ?? '';
        final state = placemark.administrativeArea ?? '';

        setState(() {
          if (city.isNotEmpty && state.isNotEmpty) {
            _startingLocation = '$city, $state';
          } else if (city.isNotEmpty) {
            _startingLocation = city;
          } else {
            _startingLocation = 'Current Location';
          }
        });
      }
    } catch (e) {
      // Keep default "Current Location" if we can't get the address
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const EnhancedUniversalHeader(
          title: 'Review Your Art Walk',
          showLogo: false,
          showBackButton: true,
          backgroundGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              ArtWalkDesignSystem.primaryTeal,
              ArtWalkDesignSystem.accentOrange,
            ],
          ),
          titleGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [
              ArtWalkDesignSystem.primaryTeal,
              ArtWalkDesignSystem.accentOrange,
            ],
          ),
        ),
        body: WorldBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildSelfieSection(),
                const SizedBox(height: 32),
                _buildStartWalkButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ArtWalkDesignSystem.hudActiveColor.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.explore,
                  color: ArtWalkDesignSystem.hudActiveColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_art_walk_review_text_ready_for_adventure'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                          alpha: 0.9,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.artWalk.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: ArtWalkDesignSystem.hudInactiveColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtWalkDesignSystem.hudBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ArtWalkDesignSystem.hudBorder.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              widget.artWalk.description,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                  alpha: 0.92,
                ),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final artworkCount = widget.artWalk.artworkIds.length;
    final estimatedDistance = widget.artWalk.estimatedDistance ?? 0.0;
    final estimatedDuration = widget.artWalk.estimatedDuration ?? 0;

    // Calculate potential XP earnings
    final potentialXP = _calculatePotentialXP(artworkCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'art_walk_art_walk_review_text_your_journey_glance'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                alpha: 0.92,
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                icon: Icons.location_on,
                label: 'art_walk_art_walk_review_text_starting_from'.tr(),
                value: _startingLocation,
                color: ArtWalkDesignSystem.primaryTeal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                icon: Icons.palette,
                label: 'art_walk_art_walk_review_text_art_pieces'.tr(),
                value:
                    '${artworkCount} ${'art_walk_art_walk_review_text_stops'.tr()}',
                color: ArtWalkDesignSystem.primaryTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                icon: Icons.directions_walk,
                label: 'art_walk_art_walk_review_text_distance'.tr(),
                value:
                    '${estimatedDistance.toStringAsFixed(1)} ${'art_walk_art_walk_review_text_miles'.tr()}',
                color: ArtWalkDesignSystem.primaryTealLight,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                icon: Icons.access_time,
                label: 'art_walk_art_walk_review_text_duration'.tr(),
                value:
                    '${estimatedDuration.round()} ${'art_walk_art_walk_review_text_min'.tr()}',
                color: ArtWalkDesignSystem.primaryTealDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // XP Reward Card
        _buildModernStatCard(
          icon: Icons.stars,
          label: 'art_walk_art_walk_review_text_potential_xp'.tr(),
          value: '$potentialXP ${'art_walk_art_walk_review_text_points'.tr()}',
          color: ArtWalkDesignSystem.accentOrange,
          subtitle: 'art_walk_art_walk_review_text_level_up_your'.tr(),
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF667eea).withValues(alpha: 0.8),
                const Color(0xFF764ba2).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.home, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_art_walk_review_text_round_trip_journey'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                          alpha: 0.9,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'art_walk_art_walk_review_text_return_starting_point'
                          .tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                          alpha: 0.7,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calculatePotentialXP(int artworkCount) {
    // Base XP for completing the art walk
    int totalXP = 100; // art_walk_completion

    // XP for visiting each art piece (assuming verified visits with photos)
    totalXP += artworkCount * 15; // art_visit_verified (15 XP each)

    // Milestone bonuses (25%, 50%, 75% progress)
    if (artworkCount >= 4) {
      totalXP += 10; // 25% milestone
      totalXP += 15; // 50% milestone
      totalXP += 20; // 75% milestone
    } else if (artworkCount >= 2) {
      totalXP += 10; // 25% milestone
      if (artworkCount >= 3) {
        totalXP += 15; // 50% milestone
      }
    }

    // Bonus for first art visit (assuming at least one piece)
    if (artworkCount > 0) {
      totalXP += 25; // first_art_visit bonus
    }

    return totalXP;
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isFullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          color: ArtWalkDesignSystem.hudInactiveColor
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: ArtWalkDesignSystem.hudInactiveColor
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                      alpha: 0.8,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: ArtWalkDesignSystem.hudInactiveColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSelfieSection() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ArtWalkDesignSystem.hudActiveColor.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_enhance,
                  color: ArtWalkDesignSystem.hudActiveColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_art_walk_review_text_capture_moment'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: ArtWalkDesignSystem.hudInactiveColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'art_walk_art_walk_review_text_start_adventure_smile'
                          .tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                          alpha: 0.9,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSelfieUploadArea(),
        ],
      ),
    );
  }

  Widget _buildSelfieUploadArea() {
    return GestureDetector(
      onTap: _captureSelfie,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selfieFile != null
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _selfieFile != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      _selfieFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'art_walk_art_walk_review_text_looking_great',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'art_walk_art_walk_review_text_tap_take_selfie'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                        alpha: 0.9,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'art_walk_art_walk_review_text_optional_show_excitement'
                        .tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: ArtWalkDesignSystem.hudInactiveColor.withValues(
                        alpha: 0.7,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStartWalkButton() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        gradient: ArtWalkDesignSystem.buttonGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading ? null : _startArtWalk,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ArtWalkDesignSystem.hudInactiveColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'art_walk_art_walk_review_text_uploading_selfie'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: ArtWalkDesignSystem.hudInactiveColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ArtWalkDesignSystem.hudInactiveColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.explore,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'art_walk_art_walk_review_text_start_my_art_walk'
                                .tr(),
                            style: GoogleFonts.spaceGrotesk(
                              color: ArtWalkDesignSystem.hudInactiveColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'art_walk_art_walk_review_text_let_adventure_begin'
                                .tr(),
                            style: GoogleFonts.spaceGrotesk(
                              color: ArtWalkDesignSystem.hudInactiveColor
                                  .withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ArtWalkDesignSystem.hudInactiveColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: ArtWalkDesignSystem.hudInactiveColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureSelfie() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null && mounted) {
        setState(() {
          _selfieFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_review_error_error_capturing_selfie'.tr(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _startArtWalk() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      // If user took a selfie, upload it as the cover image
      if (_selfieFile != null) {
        await _artWalkService.updateArtWalk(
          walkId: widget.artWalkId,
          coverImageFile: _selfieFile,
        );
      }

      if (mounted) {
        setState(() => _isUploading = false);
        Navigator.of(context).pushNamed(
          ArtWalkRoutes.experience,
          arguments: {'artWalkId': widget.artWalkId, 'artWalk': widget.artWalk},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_review_error_error_starting_art'.tr(),
            ),
          ),
        );
      }
    }
  }
}
