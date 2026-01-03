import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/group_models.dart';
import '../../services/art_community_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/moderation_service.dart';

/// Enhanced create group post screen with multimedia support and AI moderation
class CreateGroupPostScreen extends StatefulWidget {
  final GroupType groupType;
  final String postType;
  final String? groupId;

  const CreateGroupPostScreen({
    super.key,
    required this.groupType,
    required this.postType,
    this.groupId,
  });

  @override
  State<CreateGroupPostScreen> createState() => _CreateGroupPostScreenState();
}

class _CreateGroupPostScreenState extends State<CreateGroupPostScreen>
    with TickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ModerationService _moderationService = ModerationService();
  final ImagePicker _imagePicker = ImagePicker();

  List<File> _selectedImages = [];
  File? _selectedVideo;
  File? _selectedAudio;

  bool _isLoading = false;
  bool _isPickingMedia = false;
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;
  double _videoUploadProgress = 0.0;

  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  // Guard against duplicate post submissions
  bool _postSubmissionInProgress = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _communityService.dispose();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        limit: 4,
      );

      if (pickedFiles.isNotEmpty) {
        final validFiles = <File>[];

        for (final file in pickedFiles) {
          File imageFile = File(file.path);

          // Compress if needed
          if (!_storageService.isValidFileSize(imageFile)) {
            imageFile = await _storageService.compressImage(imageFile);
          }

          if (_storageService.isValidFileSize(imageFile)) {
            validFiles.add(imageFile);
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() => _selectedImages = validFiles);
        }
      }
    } catch (e) {
      _showThemedSnackBar(
        'create_group_post_images_error',
        namedArgs: {'error': '$e'},
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);

        // Check file size (max 50MB for video)
        if (videoFile.lengthSync() <= 50 * 1024 * 1024) {
          setState(() {
            _selectedVideo = videoFile;
            _selectedImages.clear(); // Clear images when video is selected
            _selectedAudio = null; // Clear audio when video is selected
          });

          // Initialize video controller
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(videoFile);
          await _videoController!.initialize();
          setState(() {});
        } else {
          _showThemedSnackBar('create_group_post_video_size_error');
        }
      }
    } catch (e) {
      _showThemedSnackBar(
        'create_group_post_video_error',
        namedArgs: {'error': '$e'},
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickAudio() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final audioFile = File(result.files.single.path!);

        // Check file size (max 10MB for audio)
        if (audioFile.lengthSync() <= 10 * 1024 * 1024) {
          setState(() {
            _selectedAudio = audioFile;
            _selectedImages.clear(); // Clear images when audio is selected
            _selectedVideo = null; // Clear video when audio is selected
          });
        } else {
          _showThemedSnackBar('create_group_post_audio_size_error');
        }
      }
    } catch (e) {
      _showThemedSnackBar(
        'create_group_post_audio_error',
        namedArgs: {'error': '$e'},
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _editImage(int index) async {
    if (index >= _selectedImages.length) return;

    try {
      final editedImage = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImageEditor(image: _selectedImages[index].readAsBytesSync()),
        ),
      );

      if (editedImage != null) {
        // Save edited image to temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(editedImage);

        setState(() {
          _selectedImages[index] = tempFile;
        });
      }
    } catch (e) {
      _showThemedSnackBar(
        'create_group_post_image_edit_error',
        namedArgs: {'error': '$e'},
      );
    }
  }

  /// Wrapper method with guard against duplicate submissions
  Future<void> _createPostWithGuard() async {
    // Double-check guard: prevent any concurrent post submissions
    if (_postSubmissionInProgress) {
      _showThemedSnackBar(
        'create_group_post_submission_pending',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _postSubmissionInProgress = true;
    try {
      await _createPost();
    } finally {
      _postSubmissionInProgress = false;
    }
  }

  Future<void> _createPost() async {
    // Validate content BEFORE setting loading state
    if (_contentController.text.trim().isEmpty &&
        _selectedImages.isEmpty &&
        _selectedVideo == null &&
        _selectedAudio == null) {
      _showThemedSnackBar('create_group_post_missing_content');
      return;
    }

    // Prevent duplicate submissions
    if (_isLoading || _isUploadingMedia) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // AI Moderation Check
      final moderationResult = await _moderationService.moderateContent(
        content: _contentController.text.trim(),
        imageFiles: _selectedImages,
        videoFile: _selectedVideo,
        audioFile: _selectedAudio,
      );

      if (!moderationResult.isApproved) {
        _showThemedSnackBar(
          'create_group_post_moderation_failed',
          namedArgs: {'reason': moderationResult.reason ?? ''},
          backgroundColor: Colors.red,
        );
        // Reset loading state before returning
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploadingMedia = false;
          });
        }
        return;
      }

      // Upload media files
      List<String> imageUrls = [];
      String? videoUrl;
      String? audioUrl;

      setState(() => _isUploadingMedia = true);

      if (_selectedImages.isNotEmpty) {
        imageUrls = await _storageService.uploadImages(_selectedImages);
      }

      if (_selectedVideo != null) {
        try {
          setState(() => _videoUploadProgress = 0.0);
          videoUrl = await _storageService.uploadVideo(
            _selectedVideo!,
            onProgress: (progress) {
              if (mounted) {
                setState(() => _videoUploadProgress = progress);
              }
            },
          );
        } catch (e) {
          final errorKey =
              e.toString().contains('App Check') ||
                  e.toString().contains('cannot parse response')
              ? 'create_group_post_video_auth_error'
              : 'create_group_post_video_upload_error';

          _showThemedSnackBar(
            errorKey,
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          );
          videoUrl = null;
        } finally {
          if (mounted) {
            setState(() => _videoUploadProgress = 0.0);
          }
        }
      }

      if (_selectedAudio != null) {
        audioUrl = await _storageService.uploadAudio(_selectedAudio!);
      }

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Get user profile information
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userName =
          userData['displayName'] ?? user.displayName ?? 'Anonymous';
      final userPhotoUrl = userData['profileImageUrl'] ?? user.photoURL ?? '';

      // Create the post data - all group posts have the same structure
      final postData = {
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': _contentController.text.trim(),
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'tags': tags,
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'isPublic': true,
        'isUserVerified': userData['isVerified'] ?? false,
        'groupType': widget.groupType.value,
        if (widget.groupId != null) 'groupId': widget.groupId,
      };

      // Save to Firestore - use 'posts' collection so it appears in unified feed
      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (!mounted) return;

      _showThemedSnackBar(
        'create_group_post_success',
        backgroundColor: _getGroupColor(),
        duration: const Duration(seconds: 5),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showThemedSnackBar(
        'create_group_post_failure',
        namedArgs: {'error': '$e'},
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingMedia = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  void _removeAudio() {
    setState(() {
      _selectedAudio = null;
      _audioPlayer?.stop();
    });
  }

  Color _getGroupColor() {
    switch (widget.groupType) {
      case GroupType.artist:
        return ArtbeatColors.primaryPurple;
      case GroupType.event:
        return ArtbeatColors.primaryGreen;
      case GroupType.artWalk:
        return ArtbeatColors.secondaryTeal;
      case GroupType.artistWanted:
        return ArtbeatColors.accentYellow;
    }
  }

  String _getGroupDisplayName() =>
      'create_group_post_group_${widget.groupType.value}'.tr();

  String _getGroupDescription() =>
      'create_group_post_group_${widget.groupType.value}_description'.tr();

  IconData _getGroupIcon() {
    switch (widget.groupType) {
      case GroupType.artist:
        return Icons.palette;
      case GroupType.event:
        return Icons.event;
      case GroupType.artWalk:
        return Icons.directions_walk;
      case GroupType.artistWanted:
        return Icons.work;
    }
  }

  LinearGradient get _groupGradient => LinearGradient(
    colors: [
      _getGroupColor(),
      _getGroupColor().withValues(alpha: 0.6),
      const Color(0xFF22D3EE),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  bool get _hasSelectedMedia =>
      _selectedImages.isNotEmpty ||
      _selectedVideo != null ||
      _selectedAudio != null;

  String _localizedOrDefault(String key, String fallbackKey) {
    final value = key.tr();
    return value == key ? fallbackKey.tr() : value;
  }

  String _getPostTypeTitle() => _localizedOrDefault(
    'create_group_post_type_${widget.postType}_title',
    'create_group_post_type_default_title',
  );

  String _getContentHint() => _localizedOrDefault(
    'create_group_post_type_${widget.postType}_hint',
    'create_group_post_type_default_hint',
  );

  String _mediaCountLabel(int count, int max) => 'create_group_post_media_count'
      .tr(namedArgs: {'count': '$count', 'max': '$max'});

  void _showThemedSnackBar(
    String key, {
    Map<String, String>? namedArgs,
    Color? backgroundColor,
    Duration? duration,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 4),
        content: Text(
          key.tr(namedArgs: namedArgs ?? const <String, String>{}),
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
    final isBusy = _isLoading || _isUploadingMedia;
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'create_group_post_title'.tr(
            namedArgs: {'group': _getGroupDisplayName()},
          ),
          glassBackground: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildUserCard(),
                        const SizedBox(height: 16),
                        _buildContentCard(),
                        const SizedBox(height: 16),
                        _buildMediaCard(),
                        if (_hasSelectedMedia) ...[
                          const SizedBox(height: 16),
                          _buildMediaPreviewCard(),
                        ],
                        const SizedBox(height: 16),
                        _buildTagsCard(),
                        if (_isUploadingMedia) ...[
                          const SizedBox(height: 16),
                          _buildUploadProgressCard(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GradientCTAButton(
                  text: 'create_group_post_submit'.tr(),
                  icon: Icons.auto_awesome,
                  onPressed: isBusy ? null : _createPostWithGuard,
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
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      showAccentGlow: true,
      accentColor: _getGroupColor(),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: _groupGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _getGroupColor().withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(_getGroupIcon(), color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPostTypeTitle(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getGroupDescription(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.72),
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

  Widget _buildUserCard() {
    final user = FirebaseAuth.instance.currentUser;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            backgroundImage: ImageUrlValidator.safeNetworkImage(user?.photoURL),
            child: !ImageUrlValidator.isValidImageUrl(user?.photoURL)
                ? const Icon(Icons.person, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'create_group_post_anonymous'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'create_group_post_user_subtitle'.tr(
                    namedArgs: {'group': _getGroupDisplayName()},
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_group_post_content_label'.tr()),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _contentController,
            hintText: _getContentHint(),
            maxLines: 6,
          ),
          const SizedBox(height: 8),
          _buildHelperText('create_group_post_content_helper'.tr()),
        ],
      ),
    );
  }

  Widget _buildMediaCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_group_post_media_title'.tr()),
          const SizedBox(height: 6),
          _buildHelperText('create_group_post_media_description'.tr()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MediaActionButton(
                  icon: Icons.photo_library,
                  label: 'create_group_post_media_images'.tr(),
                  subtitle: _mediaCountLabel(_selectedImages.length, 4),
                  onTap: _isPickingMedia ? null : _pickImages,
                  isActive: _selectedImages.isNotEmpty,
                  accentColor: _getGroupColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MediaActionButton(
                  icon: Icons.videocam,
                  label: 'create_group_post_media_video'.tr(),
                  subtitle: _mediaCountLabel(_selectedVideo == null ? 0 : 1, 1),
                  onTap: _isPickingMedia ? null : _pickVideo,
                  isActive: _selectedVideo != null,
                  accentColor: _getGroupColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MediaActionButton(
                  icon: Icons.audiotrack,
                  label: 'create_group_post_media_audio'.tr(),
                  subtitle: _mediaCountLabel(_selectedAudio == null ? 0 : 1, 1),
                  onTap: _isPickingMedia ? null : _pickAudio,
                  isActive: _selectedAudio != null,
                  accentColor: _getGroupColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreviewCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_group_post_media_preview_title'.tr()),
          const SizedBox(height: 12),
          if (_selectedImages.isNotEmpty) _buildImagesPreview(),
          if (_selectedVideo != null) ...[
            if (_selectedImages.isNotEmpty) const SizedBox(height: 12),
            _buildVideoPreview(),
          ],
          if (_selectedAudio != null) ...[
            if (_selectedImages.isNotEmpty || _selectedVideo != null)
              const SizedBox(height: 12),
            _buildAudioPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesPreview() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _selectedImages[index],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _editImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_getGroupColor()),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _removeVideo,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.audiotrack, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'create_group_post_media_audio_selected'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: _removeAudio,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_group_post_tags_label'.tr()),
          const SizedBox(height: 12),
          GlassTextField(
            controller: _tagsController,
            hintText: 'create_group_post_tags_hint'.tr(),
            prefixIcon: const Icon(Icons.tag, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildHelperText('create_group_post_tags_helper'.tr()),
        ],
      ),
    );
  }

  Widget _buildUploadProgressCard() {
    if (_selectedVideo != null && _videoUploadProgress > 0) {
      return GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('create_group_post_upload_video'.tr()),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _videoUploadProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_getGroupColor()),
            ),
            const SizedBox(height: 8),
            Text(
              'create_group_post_upload_percent'.tr(
                namedArgs: {
                  'percent': '${(_videoUploadProgress * 100).toInt()}',
                },
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('create_group_post_upload_media'.tr()),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(_getGroupColor()),
          ),
          const SizedBox(height: 8),
          Text(
            'create_group_post_upload_percent'.tr(
              namedArgs: {'percent': '${(_uploadProgress * 100).toInt()}'},
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Text _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Text _buildHelperText(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.72),
        height: 1.3,
      ),
    );
  }
}

class _MediaActionButton extends StatelessWidget {
  const _MediaActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isActive,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isActive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accentColor : Colors.white.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1,
          ),
          color: isActive
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: disabled
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
