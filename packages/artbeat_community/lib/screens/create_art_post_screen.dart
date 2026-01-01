import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/shared_widgets.dart';

import '../services/art_community_service.dart';
import '../services/firebase_storage_service.dart';

class _CreatePostPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentTeal, Color(0xFF34D399)],
  );
}

class _QuickTag {
  const _QuickTag({required this.value, required this.labelKey});

  final String value;
  final String labelKey;
}

class CreateArtPostScreen extends StatefulWidget {
  const CreateArtPostScreen({super.key});

  @override
  State<CreateArtPostScreen> createState() => _CreateArtPostScreenState();
}

class _CreateArtPostScreenState extends State<CreateArtPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  final List<File> _selectedImages = [];
  static const List<_QuickTag> _quickTags = [
    _QuickTag(value: 'Painting', labelKey: 'create_art_post_quick_tag_painting'),
    _QuickTag(value: 'Digital Art', labelKey: 'create_art_post_quick_tag_digital'),
    _QuickTag(value: 'Photography', labelKey: 'create_art_post_quick_tag_photography'),
    _QuickTag(value: 'Sculpture', labelKey: 'create_art_post_quick_tag_sculpture'),
    _QuickTag(value: 'Abstract', labelKey: 'create_art_post_quick_tag_abstract'),
    _QuickTag(value: 'Realism', labelKey: 'create_art_post_quick_tag_realism'),
    _QuickTag(value: 'Watercolor', labelKey: 'create_art_post_quick_tag_watercolor'),
    _QuickTag(value: 'Charcoal', labelKey: 'create_art_post_quick_tag_charcoal'),
    _QuickTag(value: 'Mixed Media', labelKey: 'create_art_post_quick_tag_mixed_media'),
    _QuickTag(value: 'Street Art', labelKey: 'create_art_post_quick_tag_street_art'),
  ];

  bool _isArtistPost = false;
  bool _isLoading = false;
  bool _isPickingImages = false;
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsArtist();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserIsArtist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _communityService.getArtistProfile(user.uid);
      if (mounted && profile != null) {
        setState(() => _isArtistPost = true);
      }
    }
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;

    setState(() => _isPickingImages = true);

    final picker = ImagePicker();

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(limit: 5);

      if (!mounted) return;

      if (pickedFiles.isEmpty) {
        return;
      }

      final validFiles = <File>[];
      final invalidFiles = <String>[];

      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        File imageFile = File(file.path);

        if (kDebugMode) {
          final fileSize = imageFile.lengthSync();
          final maxSize = _storageService.maxFileSizeBytes;
          print('📷 DEBUG: File $i: ${file.name}');
          print('📷 DEBUG: File size: ${fileSize} bytes');
          print('📷 DEBUG: Max allowed: $maxSize bytes');
        }

        if (!_storageService.isValidFileSize(imageFile)) {
          try {
            imageFile = await _storageService.compressImage(imageFile);
          } catch (e) {
            if (kDebugMode) {
              print('📷 ERROR: Compression failed for file $i: $e');
            }
          }
        }

        if (_storageService.isValidFileSize(imageFile)) {
          validFiles.add(imageFile);
        } else {
          invalidFiles.add(file.name);
        }
      }

      if (invalidFiles.isNotEmpty) {
        _showSnackBar(
          'create_art_post_invalid_images'.tr(
            namedArgs: {'files': invalidFiles.join(', ')},
          ),
        );
      }

      if (validFiles.isNotEmpty) {
        setState(() {
          _selectedImages
            ..clear()
            ..addAll(validFiles);
        });
      } else {
        setState(() => _selectedImages.clear());
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'create_art_post_error_picking_images'.tr(
          namedArgs: {'error': e.toString()},
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      _showSnackBar('create_art_post_error_missing_content'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];

      if (_selectedImages.isNotEmpty) {
        if (kDebugMode) {
          print('📷 DEBUG: Uploading ${_selectedImages.length} images');
        }

        setState(() => _isUploadingImages = true);
        _showSnackBar('create_art_post_uploading_images'.tr());

        imageUrls = await _storageService.uploadImages(_selectedImages);

        setState(() => _isUploadingImages = false);

        if (imageUrls.length != _selectedImages.length) {
          _showSnackBar(
            'create_art_post_upload_warning'.tr(
              namedArgs: {
                'uploaded': '${imageUrls.length}',
                'total': '${_selectedImages.length}',
              },
            ),
          );
        }
      }

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final postId = await _communityService.createPost(
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        tags: tags,
        isArtistPost: _isArtistPost,
      );

      if (!mounted) return;

      if (postId != null) {
        _showSnackBar('create_art_post_success'.tr());
        Navigator.pop(context, true);
      } else {
        _showSnackBar('create_art_post_failure'.tr());
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'create_art_post_error_creating'.tr(
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

  void _appendTag(String value) {
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (!tags.contains(value)) {
      tags.add(value);
      final nextValue = tags.join(', ');
      _tagsController
        ..text = nextValue
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: nextValue.length),
        );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'create_art_post_title'.tr(),
          glassBackground: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      _buildMediaSection(),
                      const SizedBox(height: 16),
                      _buildContentCard(),
                      const SizedBox(height: 16),
                      _buildTagsCard(),
                      if (_isArtistPost) ...[
                        const SizedBox(height: 16),
                        _buildArtistNotice(),
                      ],
                      const SizedBox(height: 16),
                      _buildQuickTags(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                HudButton.primary(
                  onPressed:
                      (_isLoading || _isUploadingImages) ? null : _createPost,
                  text: 'create_art_post_submit'.tr(),
                  isLoading: _isLoading || _isUploadingImages,
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: _CreatePostPalette.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _CreatePostPalette.accentPurple.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_mosaic, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'create_art_post_hero_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _CreatePostPalette.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'create_art_post_hero_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _CreatePostPalette.textSecondary,
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

  Widget _buildMediaSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _CreatePostPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_photo_alternate, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'create_art_post_add_media_label'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _CreatePostPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'create_art_post_add_media_description'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _CreatePostPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isEmpty)
            _buildEmptyMediaState()
          else
            _buildSelectedMedia(),
          const SizedBox(height: 16),
          HudButton.secondary(
            onPressed:
                (_isPickingImages || _isUploadingImages) ? null : _pickImages,
            text: 'create_art_post_add_media_cta'.tr(),
            icon: Icons.add,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMediaState() {
    return InkWell(
      onTap: (_isPickingImages || _isUploadingImages) ? null : _pickImages,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(
              'create_art_post_add_media_secondary'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _CreatePostPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'create_art_post_add_media_limit'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _CreatePostPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('create_art_post_selected_images_title'.tr()),
            const Spacer(),
            if (_isUploadingImages)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_selectedImages.length < 5 && !_isPickingImages)
              Text(
                '${_selectedImages.length}/5',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _CreatePostPalette.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 116,
                      height: 116,
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _isUploadingImages
                          ? null
                          : () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_art_post_content_label'.tr()),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _contentController,
            hintText: 'create_art_post_content_hint'.tr(),
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          Text(
            'create_art_post_content_helper'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _CreatePostPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_art_post_tags_label'.tr()),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _tagsController,
            hintText: 'create_art_post_tags_hint'.tr(),
            prefixIcon: const Icon(Icons.tag, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'create_art_post_tags_helper'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _CreatePostPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistNotice() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      accentColor: _CreatePostPalette.accentPurple,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _CreatePostPalette.accentPurple.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'create_art_post_artist_notice_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _CreatePostPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'create_art_post_artist_notice_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _CreatePostPalette.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTags() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_art_post_quick_tags_title'.tr()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickTags
                .map(
                  (tag) => GestureDetector(
                    onTap: () => _appendTag(tag.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Text(
                        tag.labelKey.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _CreatePostPalette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Text _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: _CreatePostPalette.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}
