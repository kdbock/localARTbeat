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
import '../../services/art_community_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/moderation_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Enhanced create post screen with multimedia support and AI moderation
class CreatePostScreen extends StatefulWidget {
  /// Optional: Pre-filled image URL (e.g., from discovery)
  final String? prefilledImageUrl;

  /// Optional: Pre-filled initial caption text
  final String? prefilledCaption;

  /// Optional: Flag indicating this is from a discovery
  final bool isDiscussionPost;

  const CreatePostScreen({
    super.key,
    this.prefilledImageUrl,
    this.prefilledCaption,
    this.isDiscussionPost = false,
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
    if (widget.prefilledCaption != null) {
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
                const SnackBar(
                  content: Text('Image skipped due to size limit'),
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
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
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
              const SnackBar(content: Text('Video file too large (max 50MB)')),
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
        ).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
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
              const SnackBar(content: Text('Audio file too large (max 10MB)')),
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
        ).showSnackBar(SnackBar(content: Text('Error picking audio: $e')));
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
        ).showSnackBar(SnackBar(content: Text('Error editing image: $e')));
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
        const SnackBar(
          content: Text('Please wait while your post is being created...'),
          duration: Duration(seconds: 2),
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
        const SnackBar(content: Text('Please add some content or media')),
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

      // Create the post
      final postId = await _communityService.createEnhancedPost(
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        tags: tags,
        isArtistPost: _isArtistPost,
        moderationStatus: moderationResult.status,
      );

      if (!mounted) return;

      if (postId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create post')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: (_isLoading || _isUploadingMedia)
                  ? null
                  : _createPostWithGuard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ArtbeatColors.primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading || _isUploadingMedia
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              _buildUserInfoSection(),
              const SizedBox(height: 20),

              // Content input
              _buildContentInput(),
              const SizedBox(height: 20),

              // Media selection buttons
              _buildMediaSelectionButtons(),
              const SizedBox(height: 20),

              // Selected media preview
              _buildMediaPreview(),

              // Tags input
              _buildTagsInput(),
              const SizedBox(height: 20),

              // Post options
              _buildPostOptions(),

              // Upload progress
              if (_isUploadingMedia) _buildUploadProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            backgroundImage: ImageUrlValidator.safeNetworkImage(user?.photoURL),
            child: !ImageUrlValidator.isValidImageUrl(user?.photoURL)
                ? const Icon(
                    Icons.person,
                    color: ArtbeatColors.primaryPurple,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Anonymous User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (_isArtistPost)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Artist',
                      style: TextStyle(
                        color: ArtbeatColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _contentController,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Share your thoughts, artwork, or creative process...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildMediaSelectionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildMediaButton(
            icon: Icons.photo_library,
            label: 'Images',
            subtitle: '${_selectedImages.length}/4',
            onTap: _pickImages,
            isActive: _selectedImages.isNotEmpty,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMediaButton(
            icon: Icons.videocam,
            label: 'Video',
            subtitle: _selectedVideo != null ? '1' : '0',
            onTap: _pickVideo,
            isActive: _selectedVideo != null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMediaButton(
            icon: Icons.audiotrack,
            label: 'Audio',
            subtitle: _selectedAudio != null ? '1' : '0',
            onTap: _pickAudio,
            isActive: _selectedAudio != null,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: _isPickingMedia ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? ArtbeatColors.primaryPurple.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? ArtbeatColors.primaryPurple : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? ArtbeatColors.primaryPurple : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isActive
                    ? ArtbeatColors.primaryPurple
                    : Colors.grey[700],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedImages.isEmpty &&
        _selectedVideo == null &&
        _selectedAudio == null &&
        _prefilledImageUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Pre-filled image preview (from discovery)
          if (_prefilledImageUrl != null) _buildPrefilledImagePreview(),

          // Images preview
          if (_selectedImages.isNotEmpty) _buildImagesPreview(),

          // Video preview
          if (_selectedVideo != null) _buildVideoPreview(),

          // Audio preview
          if (_selectedAudio != null) _buildAudioPreview(),
        ],
      ),
    );
  }

  /// Build preview for pre-filled image from discovery
  Widget _buildPrefilledImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: _prefilledImageUrl!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 120,
                height: 120,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 120,
                height: 120,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.red),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Discovery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesPreview() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback for decompression errors
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editImage(index),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _removeImage(index),
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
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: _removeVideo,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          const Positioned(
            bottom: 8,
            left: 8,
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.audiotrack, color: Colors.grey),
          const SizedBox(width: 12),
          const Expanded(child: Text('Audio file selected')),
          GestureDetector(
            onTap: _removeAudio,
            child: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _tagsController,
        decoration: InputDecoration(
          labelText: 'Tags',
          hintText: 'art, digital, painting, creative (separate by comma)',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: const Icon(Icons.tag, color: ArtbeatColors.primaryPurple),
        ),
      ),
    );
  }

  Widget _buildPostOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Post Options',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Mark as Artist Post'),
            subtitle: const Text('Show this as professional artwork'),
            value: _isArtistPost,
            onChanged: (value) {
              setState(() => _isArtistPost = value);
            },
            activeThumbColor: ArtbeatColors.primaryPurple,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    // Show video upload progress if video is being uploaded
    if (_selectedVideo != null && _videoUploadProgress > 0) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Uploading video...',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _videoUploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_videoUploadProgress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Show general media upload progress
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Uploading media...',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
