import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/art_community_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/moderation_service.dart';
import '../../models/post_model.dart';
import '../../widgets/gradient_badge.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/glass_input_decoration.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GradientBadge, GradientCTAButton, GlassInputDecoration;

/// Enhanced create post screen with multimedia support and AI moderation
class CreatePostScreen extends StatefulWidget {
  /// Optional: Pre-filled image URL (e.g., from discovery)
  final String? prefilledImageUrl;

  /// Optional: Pre-filled initial caption text
  final String? prefilledCaption;

  /// Optional: Flag indicating this is from a discovery
  final bool isDiscussionPost;

  /// Optional: Post to edit
  final PostModel? postToEdit;

  const CreatePostScreen({
    super.key,
    this.prefilledImageUrl,
    this.prefilledCaption,
    this.isDiscussionPost = false,
    this.postToEdit,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with TickerProviderStateMixin {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ArtCommunityService _communityService = ArtCommunityService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ModerationService _moderationService = ModerationService();

  List<File> _selectedImages = [];
  File? _selectedVideo;
  File? _selectedAudio;

  /// Pre-filled image URL (e.g., from discovery)
  String? _prefilledImageUrl;

  bool _isLoading = false;
  bool _isPickingMedia = false;
  bool _isUploadingMedia = false;
  bool _isArtistPost = false;
  double _uploadProgress = 0.0;
  double _videoUploadProgress = 0.0;

  bool get _hasAnyMediaSelected =>
      _selectedImages.isNotEmpty ||
      _selectedVideo != null ||
      _selectedAudio != null ||
      _prefilledImageUrl != null;

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

    // Load pre-filled data if provided
    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!.content;
      _tagsController.text = widget.postToEdit!.tags.join(', ');
      // For editing, we keep existing images/videos/audio
      // Users can add more but can't remove existing ones in this simple implementation
    } else if (widget.prefilledCaption != null) {
      _contentController.text = widget.prefilledCaption!;
    }

    _checkIfUserIsArtist();
    _loadPrefilledImage();
  }

  /// Load pre-filled image from URL (e.g., from discovery)
  Future<void> _loadPrefilledImage() async {
    if (widget.prefilledImageUrl == null) return;

    try {
      debugPrint(
        'DEBUG: Loading pre-filled image from discovery: ${widget.prefilledImageUrl}',
      );
      if (mounted) {
        setState(() {
          _prefilledImageUrl = widget.prefilledImageUrl;
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error loading pre-filled image: $e');
    }
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
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(limit: 4);

      if (pickedFiles.isNotEmpty) {
        final validFiles = <File>[];

        for (final file in pickedFiles) {
          File imageFile = File(file.path);

          // Compress if needed
          if (!_storageService.isValidFileSize(imageFile)) {
            imageFile = await _storageService.compressImage(imageFile);
          }

          // Temporarily skip validation for debugging
          // bool isValid = await _isValidImage(imageFile);
          // if (isValid && _storageService.isValidFileSize(imageFile)) {
          if (_storageService.isValidFileSize(imageFile)) {
            validFiles.add(imageFile);
          } else {
            // Log why it was skipped
            debugPrint(
              'Image skipped: ${file.path} - Size: ${imageFile.lengthSync()}, Valid: false',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('create_post_image_skipped_size'.tr()),
                ),
              );
            }
          }
        }

        if (validFiles.isNotEmpty) {
          debugPrint(
            'DEBUG: Adding ${validFiles.length} valid images to selection',
          );
          setState(() => _selectedImages = validFiles);
          debugPrint(
            'DEBUG: Total selected images now: ${_selectedImages.length}',
          );
        } else {
          debugPrint('DEBUG: No valid images found');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'create_post_error_pick_images'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    debugPrint('DEBUG: Starting video selection');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      debugPrint('DEBUG: Video picker result: ${pickedFile?.path}');

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);

        debugPrint('DEBUG: Video file size: ${videoFile.lengthSync()} bytes');

        // Check file size (max 50MB for video)
        if (videoFile.lengthSync() <= 50 * 1024 * 1024) {
          setState(() {
            _selectedVideo = videoFile;
            _selectedImages.clear(); // Clear images when video is selected
            _selectedAudio = null; // Clear audio when video is selected
          });

          debugPrint('DEBUG: Video selected successfully');

          // Initialize video controller
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(videoFile);
          await _videoController!.initialize();
          setState(() {});
        } else {
          debugPrint('DEBUG: Video file too large');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'create_post_error_video_size'.tr(namedArgs: {'limit': '50MB'}),
                ),
              ),
            );
          }
        }
      } else {
        debugPrint('DEBUG: No video file selected');
      }
    } catch (e) {
      debugPrint('DEBUG: Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'create_post_error_pick_video'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickAudio() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    debugPrint('DEBUG: Starting audio selection');

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      debugPrint('DEBUG: Audio picker result: ${result?.files.single.path}');

      if (result != null && result.files.single.path != null) {
        final audioFile = File(result.files.single.path!);

        debugPrint('DEBUG: Audio file size: ${audioFile.lengthSync()} bytes');

        // Check file size (max 10MB for audio)
        if (audioFile.lengthSync() <= 10 * 1024 * 1024) {
          setState(() {
            _selectedAudio = audioFile;
            _selectedImages.clear(); // Clear images when audio is selected
            _selectedVideo = null; // Clear video when audio is selected
          });

          debugPrint('DEBUG: Audio selected successfully');
        } else {
          debugPrint('DEBUG: Audio file too large');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'create_post_error_audio_size'.tr(namedArgs: {'limit': '10MB'}),
                ),
              ),
            );
          }
        }
      } else {
        debugPrint('DEBUG: No audio file selected');
      }
    } catch (e) {
      debugPrint('DEBUG: Error picking audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'create_post_error_pick_audio'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'create_post_error_edit_image'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  /// Wrapper method with guard against duplicate submissions
  Future<void> _createPostWithGuard() async {
    // Double-check guard: prevent any concurrent post submissions
    if (_postSubmissionInProgress) {
      debugPrint(
        'DEBUG: Post submission already in progress, ignoring duplicate tap',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('create_post_guard_message'.tr()),
          duration: const Duration(seconds: 2),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('create_post_validation_missing_content'.tr()),
        ),
      );
      return;
    }

    // Prevent duplicate submissions
    if (_isLoading || _isUploadingMedia) {
      debugPrint(
        'DEBUG: Post creation already in progress, ignoring duplicate request',
      );
      return;
    }

    // Extra debug: print file paths, existence, and size before upload
    if (_selectedImages.isNotEmpty) {
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        debugPrint('DEBUG: [UI] Image $i path: \\${file.path}');
        debugPrint('DEBUG: [UI] Image $i exists: \\${file.existsSync()}');
        debugPrint(
          'DEBUG: [UI] Image $i size: \\${file.existsSync() ? file.lengthSync() : 'N/A'} bytes',
        );
        if (!file.existsSync() || file.lengthSync() == 0) {
          debugPrint(
            'WARNING: [UI] Image $i is missing or empty and will be skipped.',
          );
        }
      }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Content moderation failed: ${moderationResult.reason}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        // IMPORTANT: Reset loading state before returning
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

      debugPrint(
        'DEBUG: Starting media upload. Selected images: ${_selectedImages.length}',
      );

      if (_selectedImages.isNotEmpty) {
        debugPrint('DEBUG: Uploading ${_selectedImages.length} images');
        imageUrls = await _storageService.uploadImages(_selectedImages);
        debugPrint('DEBUG: Upload complete. Image URLs: $imageUrls');
      }

      // Include pre-filled image URL from discovery if available
      if (_prefilledImageUrl != null && _prefilledImageUrl!.isNotEmpty) {
        debugPrint(
          'DEBUG: Including pre-filled discovery image: $_prefilledImageUrl',
        );
        imageUrls.insert(0, _prefilledImageUrl!);
      }

      // Extra debug: print imageUrls before post creation
      debugPrint('DEBUG: [UI] Final imageUrls to be saved in post: $imageUrls');

      if (_selectedVideo != null) {
        debugPrint('DEBUG: Uploading video file: ${_selectedVideo!.path}');
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
          debugPrint('DEBUG: Video upload complete. URL: $videoUrl');
        } catch (e) {
          debugPrint('DEBUG: Video upload failed: $e');
          // Provide specific error message for video upload failure
          final errorMessage =
              e.toString().contains('App Check') ||
                  e.toString().contains('cannot parse response')
              ? 'Video upload failed due to authentication issue. Please try again or contact support.'
              : 'Video upload failed. Please check your connection and try again.';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // Don't throw here - allow the post to be created without video
          videoUrl = null;
        } finally {
          if (mounted) {
            setState(() => _videoUploadProgress = 0.0);
          }
        }
      } else {
        debugPrint('DEBUG: No video selected for upload');
      }

      if (_selectedAudio != null) {
        debugPrint('DEBUG: Uploading audio file: ${_selectedAudio!.path}');
        audioUrl = await _storageService.uploadAudio(_selectedAudio!);
        debugPrint('DEBUG: Audio upload complete. URL: $audioUrl');
      } else {
        debugPrint('DEBUG: No audio selected for upload');
      }

      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      bool success;
      if (widget.postToEdit != null) {
        // Update existing post
        success = await _communityService.updatePost(
          widget.postToEdit!.id,
          content: _contentController.text.trim(),
          tags: tags,
        );
      } else {
        // Create new post
        final postId = await _communityService.createEnhancedPost(
          content: _contentController.text.trim(),
          imageUrls: imageUrls,
          videoUrl: videoUrl,
          audioUrl: audioUrl,
          tags: tags,
          isArtistPost: _isArtistPost,
          moderationStatus: moderationResult.status,
        );
        success = postId != null;
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.postToEdit != null
                  ? 'create_post_toast_updated'.tr()
                  : 'create_post_toast_created'.tr(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('create_post_error_failed'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'create_post_error_generic'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postToEdit != null;
    final title =
        isEditing ? 'create_post_edit_title'.tr() : 'screen_title_create_post'.tr();
    final actionLabel =
        isEditing ? 'create_post_update_cta'.tr() : 'create_post_publish_cta'.tr();

    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: title,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GradientCTAButton(
                text: actionLabel,
                onPressed:
                    (_isLoading || _isUploadingMedia) ? null : _createPostWithGuard,
                isLoading: _isLoading || _isUploadingMedia,
                height: 44,
                width: 160,
              ),
            ),
          ], subtitle: '',
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUserInfoSection(),
                    const SizedBox(height: 16),
                    _buildContentInput(),
                    const SizedBox(height: 16),
                    _buildMediaSelectionButtons(),
                    if (_hasAnyMediaSelected) ...[
                      const SizedBox(height: 16),
                      _buildMediaPreview(),
                    ],
                    const SizedBox(height: 16),
                    _buildTagsInput(),
                    const SizedBox(height: 16),
                    _buildPostOptions(),
                    if (_isUploadingMedia) ...[
                      const SizedBox(height: 16),
                      _buildUploadProgress(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _grotesk(double size, FontWeight weight, {double opacity = 0.92}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: Colors.white.withValues(alpha: opacity),
      letterSpacing: 0.3,
    );
  }

  Widget _sectionHeader(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _grotesk(18, FontWeight.w800)),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: _grotesk(13, FontWeight.w600, opacity: 0.7)),
        ],
      ],
    );
  }

  String _mediaCountLabel(int current, int max) {
    return 'create_post_media_counter'.tr(
      namedArgs: {
        'current': current.toString(),
        'max': max.toString(),
      },
    );
  }

  Widget _buildIconActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? background,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background ?? Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = FirebaseAuth.instance.currentUser;
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                backgroundImage: ImageUrlValidator.safeNetworkImage(user?.photoURL),
                child: !ImageUrlValidator.isValidImageUrl(user?.photoURL)
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'create_post_anonymous_user'.tr(),
                      style: _grotesk(18, FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'create_post_hero_subtitle'.tr(),
                      style: _grotesk(13, FontWeight.w600, opacity: 0.7),
                    ),
                  ],
                ),
              ),
              if (_isArtistPost)
                GradientBadge(
                  text: 'create_post_artist_badge'.tr(),
                  icon: Icons.auto_awesome,
                ),
            ],
          ),
          if (widget.isDiscussionPost) ...[
            const SizedBox(height: 16),
            GradientBadge(
              text: 'create_post_discussion_badge'.tr(),
              icon: Icons.forum_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'create_post_story_title'.tr(),
            'create_post_story_subtitle'.tr(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 6,
            style: _grotesk(15, FontWeight.w600),
            cursorColor: const Color(0xFF22D3EE),
            decoration: GlassInputDecoration(
              hintText: 'create_post_content_hint'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSelectionButtons() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'create_post_media_title'.tr(),
            'create_post_media_subtitle'.tr(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMediaButton(
                icon: Icons.photo_library_outlined,
                label: 'create_post_media_images_label'.tr(),
                subtitle: _mediaCountLabel(_selectedImages.length, 4),
                isActive: _selectedImages.isNotEmpty,
                onTap: _pickImages,
              ),
              const SizedBox(width: 16),
              _buildMediaButton(
                icon: Icons.videocam_outlined,
                label: 'create_post_media_video_label'.tr(),
                subtitle: _selectedVideo == null
                    ? _mediaCountLabel(0, 1)
                    : _mediaCountLabel(1, 1),
                isActive: _selectedVideo != null,
                onTap: _pickVideo,
              ),
              const SizedBox(width: 16),
              _buildMediaButton(
                icon: Icons.audiotrack,
                label: 'create_post_media_audio_label'.tr(),
                subtitle: _selectedAudio == null
                    ? _mediaCountLabel(0, 1)
                    : _mediaCountLabel(1, 1),
                isActive: _selectedAudio != null,
                onTap: _pickAudio,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final buttonColor =
        isActive ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isPickingMedia ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 128,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: buttonColor,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF22D3EE)
                    : Colors.white.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 12),
                Text(label, style: _grotesk(15, FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: _grotesk(12, FontWeight.w600, opacity: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('create_post_media_preview_title'.tr()),
          const SizedBox(height: 16),
          if (_prefilledImageUrl != null) ...[
            _buildPrefilledImagePreview(),
            const SizedBox(height: 16),
          ],
          if (_selectedImages.isNotEmpty) ...[
            _buildImagesPreview(),
            if (_selectedVideo != null || _selectedAudio != null)
              const SizedBox(height: 16),
          ],
          if (_selectedVideo != null) ...[
            _buildVideoPreview(),
            if (_selectedAudio != null) const SizedBox(height: 16),
          ],
          if (_selectedAudio != null) _buildAudioPreview(),
        ],
      ),
    );
  }

  Widget _buildPrefilledImagePreview() {
    return SizedBox(
      height: 168,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: _prefilledImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: Colors.white.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.white.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GradientBadge(
              text: 'create_post_prefilled_badge'.tr(),
              icon: Icons.auto_awesome,
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildIconActionButton(
              icon: Icons.close,
              onTap: () => setState(() => _prefilledImageUrl = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesPreview() {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _selectedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 152,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.08),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildIconActionButton(
                    icon: Icons.edit,
                    onTap: () => _editImage(index),
                    background: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _buildIconActionButton(
                    icon: Icons.close,
                    onTap: () => _removeImage(index),
                    background: const Color(0xFFFF3D8D).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return SizedBox(
        height: 192,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 192,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildIconActionButton(
              icon: Icons.close,
              onTap: _removeVideo,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildIconActionButton(
              icon: _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              onTap: () {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.audiotrack, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'create_post_audio_selected_label'.tr(),
              style: _grotesk(14, FontWeight.w600),
            ),
          ),
          _buildIconActionButton(
            icon: Icons.close,
            onTap: _removeAudio,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsInput() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'create_post_tags_title'.tr(),
            'create_post_tags_support'.tr(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            style: _grotesk(14, FontWeight.w600),
            cursorColor: const Color(0xFF22D3EE),
            decoration: GlassInputDecoration(
              labelText: 'create_post_tags_label'.tr(),
              hintText: 'create_post_tags_hint'.tr(),
              prefixIcon: const Icon(Icons.tag, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostOptions() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'create_post_options_title'.tr(),
            'create_post_options_subtitle'.tr(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'create_post_artist_toggle_title'.tr(),
                      style: _grotesk(15, FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'create_post_artist_toggle_subtitle'.tr(),
                      style: _grotesk(13, FontWeight.w600, opacity: 0.7),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isArtistPost,
                onChanged: (value) => setState(() => _isArtistPost = value),
                activeThumbColor: const Color(0xFF22D3EE),
                activeTrackColor: const Color(0xFF22D3EE).withValues(alpha: 0.4),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    final isVideoUpload = _selectedVideo != null && _videoUploadProgress > 0;
    final progressValue = isVideoUpload ? _videoUploadProgress : _uploadProgress;
    final title = isVideoUpload
        ? 'create_post_uploading_video_title'.tr()
        : 'create_post_uploading_media_title'.tr();

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _grotesk(15, FontWeight.w700)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progressValue * 100).toInt()}%',
            style: _grotesk(12, FontWeight.w600, opacity: 0.7),
          ),
        ],
      ),
    );
  }
}
