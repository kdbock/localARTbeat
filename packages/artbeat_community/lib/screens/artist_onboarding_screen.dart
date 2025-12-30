import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:artbeat_core/artbeat_core.dart';

import '../models/art_models.dart';
import '../services/art_community_service.dart';
import '../services/firebase_storage_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_input_decoration.dart';
import '../widgets/hud_button.dart';
import '../widgets/hud_top_bar.dart';
import '../widgets/world_background.dart';

class _OnboardingPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentGreen = Color(0xFF34D399);
  static const Color accentPink = Color(0xFFFF3D8D);

  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentTeal, accentGreen],
  );
}

class _SpecialtyOption {
  const _SpecialtyOption({required this.value, required this.labelKey});

  final String value;
  final String labelKey;
}

class ArtistOnboardingScreen extends StatefulWidget {
  const ArtistOnboardingScreen({super.key});

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  static const int _totalSteps = 3;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();

  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  final List<_SpecialtyOption> _specialtyOptions = const [
    _SpecialtyOption(
      value: 'Painting',
      labelKey: 'artist_onboarding_specialty_painting',
    ),
    _SpecialtyOption(
      value: 'Drawing',
      labelKey: 'artist_onboarding_specialty_drawing',
    ),
    _SpecialtyOption(
      value: 'Sculpture',
      labelKey: 'artist_onboarding_specialty_sculpture',
    ),
    _SpecialtyOption(
      value: 'Photography',
      labelKey: 'artist_onboarding_specialty_photography',
    ),
    _SpecialtyOption(
      value: 'Digital Art',
      labelKey: 'artist_onboarding_specialty_digital_art',
    ),
    _SpecialtyOption(
      value: 'Mixed Media',
      labelKey: 'artist_onboarding_specialty_mixed_media',
    ),
    _SpecialtyOption(
      value: 'Printmaking',
      labelKey: 'artist_onboarding_specialty_printmaking',
    ),
    _SpecialtyOption(
      value: 'Ceramics',
      labelKey: 'artist_onboarding_specialty_ceramics',
    ),
    _SpecialtyOption(
      value: 'Textile Art',
      labelKey: 'artist_onboarding_specialty_textile_art',
    ),
    _SpecialtyOption(
      value: 'Street Art',
      labelKey: 'artist_onboarding_specialty_street_art',
    ),
    _SpecialtyOption(
      value: 'Illustration',
      labelKey: 'artist_onboarding_specialty_illustration',
    ),
    _SpecialtyOption(
      value: 'Graphic Design',
      labelKey: 'artist_onboarding_specialty_graphic_design',
    ),
  ];

  final List<String> _selectedSpecialties = [];

  File? _profileImage;
  final List<File> _portfolioImages = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      _displayNameController.text = user.displayName!;
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        if (_storageService.isValidFileSize(imageFile)) {
          setState(() => _profileImage = imageFile);
        } else {
          _showSnackBar('artist_onboarding_profile_image_size_error'.tr());
        }
      }
    } catch (e) {
      _showSnackBar(
        'artist_onboarding_profile_image_picker_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _pickPortfolioImages() async {
    final picker = ImagePicker();

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        limit: 10,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFiles.isEmpty) {
        return;
      }

      final validFiles = <File>[];

      for (final file in pickedFiles) {
        final imageFile = File(file.path);
        if (_storageService.isValidFileSize(imageFile)) {
          validFiles.add(imageFile);
        }
      }

      if (validFiles.isNotEmpty) {
        setState(() => _portfolioImages.addAll(validFiles));
      }

      if (validFiles.length != pickedFiles.length) {
        _showSnackBar('artist_onboarding_portfolio_image_size_notice'.tr());
      }
    } catch (e) {
      _showSnackBar(
        'artist_onboarding_portfolio_picker_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    }
  }

  void _removePortfolioImage(int index) {
    setState(() => _portfolioImages.removeAt(index));
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        _selectedSpecialties.remove(specialty);
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
  }

  Future<void> _createArtistProfile() async {
    if (_displayNameController.text.trim().isEmpty) {
      _showSnackBar('artist_onboarding_display_name_required'.tr());
      return;
    }

    if (_selectedSpecialties.isEmpty) {
      _showSnackBar('artist_onboarding_specialty_required'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      String? profileImageUrl;
      if (_profileImage != null) {
        setState(() => _isUploadingImages = true);
        profileImageUrl = await _storageService.uploadProfileImage(
          _profileImage!,
          user.uid,
        );
        setState(() => _isUploadingImages = false);
      }

      final portfolioImageUrls = <String>[];
      if (_portfolioImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        for (final imageFile in _portfolioImages) {
          try {
            final url = await _storageService.uploadPortfolioImage(
              imageFile,
              user.uid,
            );
            portfolioImageUrls.add(url);
          } catch (e) {
            AppLogger.error('Failed to upload portfolio image: $e');
          }
        }
        setState(() => _isUploadingImages = false);
      }

      final artistProfile = ArtistProfile(
        userId: user.uid,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: profileImageUrl ?? '',
        portfolioImages: portfolioImageUrls,
        specialties: _selectedSpecialties,
        isVerified: false,
        followersCount: 0,
        createdAt: DateTime.now(),
      );

      final success = await _communityService.updateArtistProfile(artistProfile);

      if (!mounted) return;

      if (success) {
        _showSnackBar('artist_onboarding_success'.tr());
        Navigator.pop(context, true);
      } else {
        _showSnackBar('artist_onboarding_failure'.tr());
      }
    } catch (e) {
      _showSnackBar(
        'artist_onboarding_submit_error'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'artist_onboarding_step_basic_title'.tr(),
      'artist_onboarding_step_specialties_title'.tr(),
      'artist_onboarding_step_portfolio_title'.tr(),
    ];

    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'artist_onboarding_title'.tr(),
          glassBackground: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildProgressIndicator(stepTitles),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey(_currentStep),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._buildStepContent(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: HudButton.secondary(
                          onPressed: _isLoading ? null : _previousStep,
                          text: 'artist_onboarding_back'.tr(),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: HudButton.primary(
                        onPressed: (_isLoading || _isUploadingImages)
                            ? null
                            : _currentStep < _totalSteps - 1
                                ? _nextStep
                                : _createArtistProfile,
                        text: _currentStep < _totalSteps - 1
                            ? 'artist_onboarding_next'.tr()
                            : 'artist_onboarding_submit'.tr(),
                        isLoading: _isLoading || _isUploadingImages,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: _OnboardingPalette.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _OnboardingPalette.accentPurple.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'artist_onboarding_hero_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _OnboardingPalette.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'artist_onboarding_hero_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _OnboardingPalette.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(List<String> stepTitles) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'artist_onboarding_step_progress'.tr(
              namedArgs: {
                'current': '${_currentStep + 1}',
                'total': '$_totalSteps',
              },
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _OnboardingPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              _totalSteps,
              (index) {
                final isComplete = index < _currentStep;
                final isActive = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 6,
                      right: index == _totalSteps - 1 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isComplete || isActive
                          ? _OnboardingPalette.primaryGradient
                          : null,
                      color: isComplete || isActive
                          ? null
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              stepTitles.length,
              (index) => Expanded(
                child: Text(
                  stepTitles[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight:
                        index == _currentStep ? FontWeight.w800 : FontWeight.w600,
                    color: index == _currentStep
                        ? Colors.white
                        : _OnboardingPalette.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoContent();
      case 1:
        return _buildSpecialtiesContent();
      case 2:
        return _buildPortfolioContent();
      default:
        return const [];
    }
  }

  List<Widget> _buildBasicInfoContent() {
    return [
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'artist_onboarding_profile_section_title'.tr(),
              subtitle: 'artist_onboarding_profile_section_subtitle'.tr(),
            ),
            const SizedBox(height: 20),
            Center(child: _buildProfileImagePicker()),
            const SizedBox(height: 12),
            Text(
              'artist_onboarding_profile_photo_hint'.tr(),
              textAlign: TextAlign.center,
              style: _helperStyle,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'artist_onboarding_identity_section_title'.tr(),
              subtitle: 'artist_onboarding_identity_section_subtitle'.tr(),
            ),
            const SizedBox(height: 20),
            GlassTextField(
              controller: _displayNameController,
              labelText: 'artist_onboarding_display_name_label'.tr(),
              hintText: 'artist_onboarding_display_name_hint'.tr(),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _bioController,
              labelText: 'artist_onboarding_bio_label'.tr(),
              hintText: 'artist_onboarding_bio_hint'.tr(),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _websiteController,
              labelText: 'artist_onboarding_website_label'.tr(),
              hintText: 'artist_onboarding_website_hint'.tr(),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            GlassTextField(
              controller: _instagramController,
              labelText: 'artist_onboarding_instagram_label'.tr(),
              hintText: 'artist_onboarding_instagram_hint'.tr(),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSpecialtiesContent() {
    return [
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'artist_onboarding_step_specialties_title'.tr(),
              subtitle: 'artist_onboarding_step_specialties_desc'.tr(),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _specialtyOptions
                  .map((option) => _buildSpecialtyChip(option))
                  .toList(),
            ),
            if (_selectedSpecialties.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'artist_onboarding_specialties_validation'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _OnboardingPalette.accentPink,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPortfolioContent() {
    return [
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'artist_onboarding_step_portfolio_title'.tr(),
              subtitle: 'artist_onboarding_step_portfolio_desc'.tr(),
            ),
            const SizedBox(height: 16),
            Text(
              'artist_onboarding_portfolio_limit'.tr(namedArgs: {'total': '10'}),
              style: _helperStyle,
            ),
            const SizedBox(height: 16),
            if (_portfolioImages.isEmpty)
              _buildEmptyPortfolioCard()
            else
              _buildPortfolioList(),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildReadyCard(),
    ];
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _OnboardingPalette.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 2,
          ),
          gradient: _profileImage == null
              ? const LinearGradient(
                  colors: [
                    Color(0x14FFFFFF),
                    Color(0x06000000),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          image: _profileImage != null
              ? DecorationImage(
                  image: FileImage(_profileImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _profileImage == null
            ? const Icon(
                Icons.photo_camera,
                size: 40,
                color: _OnboardingPalette.accentTeal,
              )
            : null,
      ),
    );
  }

  Widget _buildSpecialtyChip(_SpecialtyOption option) {
    final isSelected = _selectedSpecialties.contains(option.value);

    return GestureDetector(
      onTap: () => _toggleSpecialty(option.value),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isSelected ? _OnboardingPalette.primaryGradient : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: isSelected ? 0.5 : 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _OnboardingPalette.accentTeal.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              option.labelKey.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPortfolioCard() {
    return GestureDetector(
      onTap: _pickPortfolioImages,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_photo_alternate,
                size: 42,
                color: _OnboardingPalette.accentTeal,
              ),
              const SizedBox(height: 12),
              Text(
                'artist_onboarding_portfolio_empty_cta'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'artist_onboarding_portfolio_empty_subtitle'.tr(),
                style: _helperStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'artist_onboarding_portfolio_count'.tr(
                namedArgs: {
                  'count': '${_portfolioImages.length}',
                  'total': '10',
                },
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _OnboardingPalette.textSecondary,
              ),
            ),
            const Spacer(),
            if (_portfolioImages.length < 10)
              HudButton.secondary(
                onPressed: _pickPortfolioImages,
                text: 'artist_onboarding_portfolio_add_more'.tr(),
                width: 150,
                height: 44,
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _portfolioImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildPortfolioThumbnail(index),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(
            _portfolioImages[index],
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removePortfolioImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyCard() {
    final perks = [
      'artist_onboarding_ready_point_badges'.tr(),
      'artist_onboarding_ready_point_portfolio'.tr(),
      'artist_onboarding_ready_point_connections'.tr(),
      'artist_onboarding_ready_point_commissions'.tr(),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _OnboardingPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _OnboardingPalette.accentPurple.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.celebration, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'artist_onboarding_ready_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'artist_onboarding_ready_subtitle'.tr(),
                      style: _helperStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...perks.map(
            (perk) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: _OnboardingPalette.accentGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      perk,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _helperStyle => GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _OnboardingPalette.textSecondary,
        letterSpacing: 0.2,
      );
}
