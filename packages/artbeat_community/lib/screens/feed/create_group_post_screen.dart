import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/art_community_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/moderation_service.dart';
import '../../models/group_models.dart';
import 'package:artbeat_core/artbeat_core.dart';

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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video file too large (max 50MB)')),
            );
          }
        }
      }
    } catch (e) {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Audio file too large (max 10MB)')),
            );
          }
        }
      }
    } catch (e) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Post created successfully! It may take a moment to appear in your feeds.',
          ),
          backgroundColor: _getGroupColor(),
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.pop(context, true);
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

  String _getGroupDisplayName() {
    switch (widget.groupType) {
      case GroupType.artist:
        return 'Artist';
      case GroupType.event:
        return 'Event';
      case GroupType.artWalk:
        return 'Art Walk';
      case GroupType.artistWanted:
        return 'Artist Wanted';
    }
  }

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

  String _getPostTypeTitle() {
    switch (widget.postType) {
      case 'artwork':
        return 'Share Artwork';
      case 'process':
        return 'Process Video';
      case 'update':
        return 'Artist Update';
      case 'hosting':
        return 'Hosting Event';
      case 'attending':
        return 'Attending Event';
      case 'photos':
        return 'Event Photos';
      case 'artwalk':
        return 'Art Walk Adventure';
      case 'route':
        return 'New Route';
      case 'project':
        return 'Project Request';
      case 'services':
        return 'Offer Services';
      default:
        return 'Create Post';
    }
  }

  String _getContentHint() {
    switch (widget.postType) {
      case 'artwork':
        return 'Describe your artwork, inspiration, or technique...';
      case 'process':
        return 'Share details about your creative process...';
      case 'update':
        return 'What\'s on your mind? Share with fellow artists...';
      case 'hosting':
        return 'Tell us about your event - what, when, where...';
      case 'attending':
        return 'Why are you excited about this event?...';
      case 'photos':
        return 'Share your experience at this event...';
      case 'artwalk':
        return 'Describe your art walk route and discoveries...';
      case 'route':
        return 'Describe the route, highlights, and difficulty...';
      case 'project':
        return 'Describe your project, timeline, and requirements...';
      case 'services':
        return 'Describe your skills, experience, and availability...';
      default:
        return 'Share your thoughts...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Create ${_getGroupDisplayName()} Post',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _getGroupColor(),
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
                foregroundColor: _getGroupColor(),
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
              // Post type header
              _buildPostTypeHeader(),
              const SizedBox(height: 20),

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

              // Upload progress
              if (_isUploadingMedia) _buildUploadProgress(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getGroupColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getGroupColor().withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(_getGroupIcon(), color: _getGroupColor(), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPostTypeTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getGroupColor(),
                  ),
                ),
                Text(
                  'Share with the ${_getGroupDisplayName().toLowerCase()} community',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            backgroundColor: _getGroupColor().withValues(alpha: 0.1),
            backgroundImage: ImageUrlValidator.safeNetworkImage(user?.photoURL),
            child: !ImageUrlValidator.isValidImageUrl(user?.photoURL)
                ? Icon(Icons.person, color: _getGroupColor(), size: 24)
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
                Text(
                  'Posting to ${_getGroupDisplayName()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          hintText: _getContentHint(),
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
              ? _getGroupColor().withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _getGroupColor() : Colors.grey[300]!,
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
              color: isActive ? _getGroupColor() : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isActive ? _getGroupColor() : Colors.grey[700],
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
        _selectedAudio == null) {
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
          prefixIcon: Icon(Icons.tag, color: _getGroupColor()),
        ),
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
              valueColor: AlwaysStoppedAnimation<Color>(_getGroupColor()),
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
            valueColor: AlwaysStoppedAnimation<Color>(_getGroupColor()),
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
