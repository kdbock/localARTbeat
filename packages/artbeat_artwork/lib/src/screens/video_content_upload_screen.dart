import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        ArtbeatColors,
        EnhancedUniversalHeader,
        MainLayout,
        AppLogger;
import 'package:artbeat_artwork/artbeat_artwork.dart' show ArtworkService;

// Video processing imports - simplified for now
import 'package:video_player/video_player.dart';

enum VideoContentUploadStep { content, basicInfo, details, review }

class VideoContentUploadScreen extends StatefulWidget {
  final String? contentId;

  const VideoContentUploadScreen({super.key, this.contentId});

  @override
  State<VideoContentUploadScreen> createState() =>
      _VideoContentUploadScreenState();
}

class _VideoContentUploadScreenState extends State<VideoContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Wizard state
  int _currentStepIndex = 0;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _directorController;
  late final TextEditingController _producerController;
  late final TextEditingController _editorController;
  late final TextEditingController _cinematographerController;
  late final TextEditingController _productionCompanyController;
  late final TextEditingController _aspectRatioController;
  late final TextEditingController _frameRateController;
  late final TextEditingController _locationController;
  late final TextEditingController _equipmentController;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Services
  final ArtworkService _artworkService = ArtworkService();

  File? _thumbnailFile;
  bool _isForSale = false;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  final List<String> _genres = [];
  String _contentType = 'Video Art';
  String _releaseSchedule = 'immediate';

  // Video management
  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  Duration _videoDuration = Duration.zero;
  bool _isSaving = false;

  // Video metadata
  String _videoFormat = '';
  int _fileSize = 0;
  final int _bitrate = 0;
  int _width = 0;
  int _height = 0;
  final double _frameRate = 0.0;
  bool _isValidVideo = false;

  // Thumbnail data
  bool _isGeneratingThumbnail = false;

  final List<String> _availableGenres = [
    'Abstract',
    'Documentary',
    'Experimental',
    'Animation',
    'Music Video',
    'Narrative',
    'Performance',
    'Installation',
    'Interactive',
    'Live Art',
    'Digital Art',
    'Mixed Media',
    'Conceptual',
    'Surreal',
    'Minimalist',
    'Avant-garde',
    'Traditional',
    'Contemporary',
  ];

  final List<String> _contentTypes = [
    'Video Art',
    'Short Film',
    'Documentary',
    'Animation',
    'Music Video',
    'Performance Art',
    'Installation Art',
    'Interactive Art',
  ];

  final List<String> _releaseSchedules = [
    'immediate',
    'weekly',
    'bi-weekly',
    'monthly',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _directorController = TextEditingController();
    _producerController = TextEditingController();
    _editorController = TextEditingController();
    _cinematographerController = TextEditingController();
    _productionCompanyController = TextEditingController();
    _aspectRatioController = TextEditingController();
    _frameRateController = TextEditingController();
    _locationController = TextEditingController();
    _equipmentController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _directorController.dispose();
    _producerController.dispose();
    _editorController.dispose();
    _cinematographerController.dispose();
    _productionCompanyController.dispose();
    _aspectRatioController.dispose();
    _frameRateController.dispose();
    _locationController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!mounted) return;

      setState(() {
        _tierLevel = SubscriptionTier.values.firstWhere(
          (tier) => tier.name == userDoc.get('subscriptionTier'),
          orElse: () => SubscriptionTier.free,
        );
      });

      final artworkDocs = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _artworkCount = artworkDocs.count ?? 0;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user data: $e');
    }
  }

  bool get _canUpload {
    int limit = 3;
    switch (_tierLevel) {
      case SubscriptionTier.free:
        limit = 3;
        break;
      case SubscriptionTier.starter:
        limit = 25;
        break;
      case SubscriptionTier.creator:
        limit = 100;
        break;
      case SubscriptionTier.business:
      case SubscriptionTier.enterprise:
        limit = 999999;
        break;
      default:
        limit = 3;
    }
    return _artworkCount < limit;
  }

  // Video management methods
  Future<void> _selectVideoFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _videoFile = File(result.files.single.path!);
        });
        await _processVideoFile();
      }
    } catch (e) {
      AppLogger.error('Error selecting video file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'video_content_upload_file_error'.tr(args: [e.toString()]),
            ),
          ),
        );
      }
    }
  }

  Future<void> _processVideoFile() async {
    if (_videoFile == null) return;

    try {
      setState(() => _isGeneratingThumbnail = true);

      // Extract basic metadata
      final fileSize = await _videoFile!.length();
      final fileName = _videoFile!.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      // Basic validation
      if (!_isValidVideoFormat(extension)) {
        setState(() => _isValidVideo = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('video_content_upload_unsupported_format'.tr()),
            ),
          );
        }
        return;
      }

      // Check file size (500MB for free, 2GB for premium)
      final maxSize = _tierLevel == SubscriptionTier.free
          ? 500 * 1024 * 1024
          : 2 * 1024 * 1024 * 1024;
      if (fileSize > maxSize) {
        setState(() => _isValidVideo = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'video_content_upload_file_too_large'.tr(
                  args: [
                    maxSize > 1024 * 1024 * 1024
                        ? '${maxSize ~/ (1024 * 1024 * 1024)}GB'
                        : '${maxSize ~/ (1024 * 1024)}MB',
                  ],
                ),
              ),
            ),
          );
        }
        return;
      }

      // Initialize video controller
      _videoController = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoDuration = _videoController!.value.duration;
              _width = _videoController!.value.size.width.toInt();
              _height = _videoController!.value.size.height.toInt();
            });
          }
        });

      // Generate thumbnail
      await _generateThumbnail();

      setState(() {
        _fileSize = fileSize;
        _videoFormat = extension.toUpperCase();
        _isValidVideo = true;
        _isGeneratingThumbnail = false;
      });
    } catch (e) {
      AppLogger.error('Error processing video file: $e');
      setState(() => _isGeneratingThumbnail = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'video_content_upload_process_error'.tr(args: [e.toString()]),
            ),
          ),
        );
      }
    }
  }

  Future<void> _generateThumbnail() async {
    // Simplified thumbnail generation - in real implementation would extract frame
    // For now, we'll use a placeholder or ask user to select thumbnail
    setState(() => _isGeneratingThumbnail = false);
  }

  bool _isValidVideoFormat(String extension) {
    const validFormats = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv'];
    return validFormats.contains(extension);
  }

  void _togglePlayback() {
    if (_videoController == null) return;

    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _selectThumbnail() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _thumbnailFile = File(image.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error selecting thumbnail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'video_content_upload_thumbnail_error'.tr(args: [e.toString()]),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadVideoContent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('video_content_upload_no_video_error'.tr())),
      );
      return;
    }

    if (!_isValidVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('video_content_upload_invalid_content'.tr())),
      );
      return;
    }

    if (!_canUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('video_content_upload_limit'.tr())),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      // Use thumbnail as the main image for the artwork
      final imageFile = _thumbnailFile ?? _videoFile!;

      // Create artwork using ArtworkService
      final artworkId = await _artworkService.uploadArtwork(
        imageFile: imageFile,
        title: _titleController.text,
        description: _descriptionController.text,
        medium: 'Video Art',
        styles: _genres,
        tags: [],
        price: _isForSale ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        isForSale: _isForSale,
      );

      // Update artwork metadata for video content
      final artwork = await _artworkService.getArtworkById(artworkId);
      if (artwork != null) {
        final updatedData = {
          'contentType': 'video',
          'videoMetadata': {
            'duration': _videoDuration.inMilliseconds,
            'format': _videoFormat,
            'fileSize': _fileSize,
            'bitrate': _bitrate,
            'width': _width,
            'height': _height,
            'frameRate': _frameRate,
            'aspectRatio': _aspectRatioController.text.isNotEmpty
                ? _aspectRatioController.text
                : '${_width}:${_height}',
          },
          'productionInfo': {
            'director': _directorController.text.isNotEmpty
                ? _directorController.text
                : null,
            'producer': _producerController.text.isNotEmpty
                ? _producerController.text
                : null,
            'editor': _editorController.text.isNotEmpty
                ? _editorController.text
                : null,
            'cinematographer': _cinematographerController.text.isNotEmpty
                ? _cinematographerController.text
                : null,
            'productionCompany': _productionCompanyController.text.isNotEmpty
                ? _productionCompanyController.text
                : null,
            'location': _locationController.text.isNotEmpty
                ? _locationController.text
                : null,
            'equipment': _equipmentController.text.isNotEmpty
                ? _equipmentController.text
                : null,
          },
          'releaseSchedule': _releaseSchedule,
          'recordingDate': DateTime.now().toIso8601String(),
        };

        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .update(updatedData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('video_content_upload_success'.tr())),
        );
        Navigator.of(context).pop(artworkId);
      }
    } catch (e) {
      AppLogger.error('Error uploading video content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'video_content_upload_error'.tr(args: [e.toString()]),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onStepContinue() {
    if (_currentStepIndex < 3) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      _uploadVideoContent();
    }
  }

  void _onStepCancel() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _onStepTapped(int index) {
    setState(() {
      _currentStepIndex = index;
    });
  }

  StepState _getStepState(int stepIndex) {
    if (stepIndex < _currentStepIndex) return StepState.complete;
    if (stepIndex == _currentStepIndex) return StepState.editing;
    return StepState.disabled;
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          if (_currentStepIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                child: Text('back'.tr()),
              ),
            ),
          if (_currentStepIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStepIndex == 3 ? 'upload'.tr() : 'continue'.tr(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'video_content_upload_content_desc'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Video file selection
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_videoFile == null) ...[
                Icon(
                  Icons.video_file_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'video_content_upload_select_video'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'video_content_upload_supported_formats'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectVideoFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text('video_content_upload_choose_file'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                // Video preview
                if (_videoController != null &&
                    _videoController!.value.isInitialized) ...[
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoController!),
                        IconButton(
                          onPressed: _togglePlayback,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_videoDuration.inMinutes}:${(_videoDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_width}x$_height',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _videoFile!.path.split('/').last,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _videoFile = null;
                          _videoController?.dispose();
                          _videoController = null;
                          _isValidVideo = false;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Thumbnail selection
        Text(
          'video_content_upload_thumbnail'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_thumbnailFile == null) ...[
                Icon(Icons.image_outlined, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'video_content_upload_select_thumbnail'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _selectThumbnail,
                  icon: const Icon(Icons.photo),
                  label: Text('video_content_upload_choose_thumbnail'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _thumbnailFile!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _thumbnailFile!.path.split('/').last,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _thumbnailFile = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        if (_isGeneratingThumbnail)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'title'.tr(),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'video_content_upload_title_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'description'.tr(),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'video_content_upload_description_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _contentType,
            decoration: InputDecoration(
              labelText: 'video_content_upload_content_type'.tr(),
              border: const OutlineInputBorder(),
            ),
            items: _contentTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _contentType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _availableGenres.map((genre) {
              final isSelected = _genres.contains(genre);
              return FilterChip(
                label: Text(genre),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _genres.add(genre);
                    } else {
                      _genres.remove(genre);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'video_content_upload_production_info'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _directorController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_director'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _producerController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_producer'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _editorController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_editor'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cinematographerController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_cinematographer'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _productionCompanyController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_production_company'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_location'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _equipmentController,
          decoration: InputDecoration(
            labelText: 'video_content_upload_equipment'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'video_content_upload_technical_specs'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _aspectRatioController,
                decoration: InputDecoration(
                  labelText: 'video_content_upload_aspect_ratio'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _frameRateController,
                decoration: InputDecoration(
                  labelText: 'video_content_upload_frame_rate'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'video_content_upload_pricing'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _isForSale,
              onChanged: (value) {
                setState(() {
                  _isForSale = value ?? false;
                });
              },
            ),
            Text('video_content_upload_for_sale'.tr()),
          ],
        ),
        if (_isForSale) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'price'.tr(),
              border: const OutlineInputBorder(),
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isForSale && (value?.isEmpty ?? true)) {
                return 'video_content_upload_price_required'.tr();
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: _releaseSchedule,
          decoration: InputDecoration(
            labelText: 'video_content_upload_release_schedule'.tr(),
            border: const OutlineInputBorder(),
          ),
          items: _releaseSchedules.map((schedule) {
            return DropdownMenuItem(
              value: schedule,
              child: Text('video_content_upload_schedule_$schedule'.tr()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _releaseSchedule = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'video_content_upload_review'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        _buildReviewItem('title'.tr(), _titleController.text),
        _buildReviewItem('description'.tr(), _descriptionController.text),
        _buildReviewItem(
          'video_content_upload_content_type'.tr(),
          _contentType,
        ),
        _buildReviewItem('genres'.tr(), _genres.join(', ')),
        if (_directorController.text.isNotEmpty)
          _buildReviewItem(
            'video_content_upload_director'.tr(),
            _directorController.text,
          ),
        if (_producerController.text.isNotEmpty)
          _buildReviewItem(
            'video_content_upload_producer'.tr(),
            _producerController.text,
          ),
        if (_isForSale)
          _buildReviewItem('price'.tr(), '\$${_priceController.text}'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'video_content_upload_review_note'.tr(),
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'video_content_upload_title'.tr(),
          showLogo: false,
          showBackButton: true,
        ),
        body: Column(
          children: [
            if (!_canUpload)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'video_content_upload_limit'.tr(),
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            Expanded(
              child: Stepper(
                currentStep: _currentStepIndex,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                onStepTapped: _onStepTapped,
                controlsBuilder: _buildStepperControls,
                steps: [
                  Step(
                    title: Text('video_content_upload_step_content'.tr()),
                    subtitle: Text(
                      'video_content_upload_step_content_desc'.tr(),
                    ),
                    content: _buildContentStep(),
                    isActive: _currentStepIndex >= 0,
                    state: _getStepState(0),
                  ),
                  Step(
                    title: Text('video_content_upload_step_basic_info'.tr()),
                    subtitle: Text(
                      'video_content_upload_step_basic_info_desc'.tr(),
                    ),
                    content: _buildBasicInfoStep(),
                    isActive: _currentStepIndex >= 1,
                    state: _getStepState(1),
                  ),
                  Step(
                    title: Text('video_content_upload_step_details'.tr()),
                    subtitle: Text(
                      'video_content_upload_step_details_desc'.tr(),
                    ),
                    content: _buildDetailsStep(),
                    isActive: _currentStepIndex >= 2,
                    state: _getStepState(2),
                  ),
                  Step(
                    title: Text('video_content_upload_step_review'.tr()),
                    subtitle: Text(
                      'video_content_upload_step_review_desc'.tr(),
                    ),
                    content: _buildReviewStep(),
                    isActive: _currentStepIndex >= 3,
                    state: _getStepState(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
