import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_artist/artbeat_artist.dart' show SubscriptionService;
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        ArtbeatColors,
        EnhancedStorageService,
        EnhancedUniversalHeader,
        MainLayout,
        ImageUrlValidator;

/// Enhanced artwork upload screen with support for multiple media types
class EnhancedArtworkUploadScreen extends StatefulWidget {
  final String? artworkId; // For editing existing artwork
  final File? imageFile; // For new artwork from capture
  final Position? location; // For location data from capture

  const EnhancedArtworkUploadScreen({
    super.key,
    this.artworkId,
    this.imageFile,
    this.location,
  });

  @override
  State<EnhancedArtworkUploadScreen> createState() =>
      _EnhancedArtworkUploadScreenState();
}

enum UploadStep {
  media,
  basicInfo,
  details,
  pricing,
  review,
}

class _EnhancedArtworkUploadScreenState
    extends State<EnhancedArtworkUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Wizard state
  UploadStep _currentStep = UploadStep.media;
  int _currentStepIndex = 0;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _keywordController = TextEditingController();

  // New rich metadata controllers
  final _creationProcessController = TextEditingController();
  final _inspirationController = TextEditingController();
  final _techniqueController = TextEditingController();

  // Firebase instances
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _subscriptionService = SubscriptionService();

  // State variables
  File? _mainImageFile;
  final List<File> _additionalImageFiles = [];
  final List<File> _videoFiles = [];
  final List<File> _audioFiles = [];

  String? _imageUrl;
  List<String> _additionalImageUrls = [];
  List<String> _videoUrls = [];
  List<String> _audioUrls = [];

  bool _isForSale = false;
  bool _isLoading = false;
  String? _mainImageError;
  bool _canUpload = true;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  String _medium = '';
  List<String> _styles = [];
  List<String> _tags = [];
  List<String> _hashtags = [];
  List<String> _keywords = [];

  // New rich metadata
  String _dimensionUnit = 'cm'; // cm or inches
  List<String> _colorPalette = [];

  // Upload progress tracking
  double _mainImageUploadProgress = 0.0;
  final bool _isUploadingMainImage = false;

  // Available options
  final List<String> _availableMediums = [
    'Oil Paint',
    'Acrylic',
    'Watercolor',
    'Charcoal',
    'Pastel',
    'Digital',
    'Mixed Media',
    'Sculpture',
    'Photography',
    'Textiles',
    'Ceramics',
    'Printmaking',
    'Pen & Ink',
    'Pencil',
    'Video Art',
    'Sound Art',
    'Performance Art',
    'Installation',
  ];

  final List<String> _availableStyles = [
    'Abstract',
    'Realism',
    'Impressionism',
    'Expressionism',
    'Minimalism',
    'Pop Art',
    'Surrealism',
    'Cubism',
    'Contemporary',
    'Folk Art',
    'Street Art',
    'Illustration',
    'Fantasy',
    'Portrait',
    'Landscape',
    'Still Life',
    'Conceptual',
    'Photorealistic',
  ];

  final List<String> _dimensionUnits = ['cm', 'inches'];

  final List<String> _availableColors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Brown',
    'Black',
    'White',
    'Gray',
    'Cyan',
    'Magenta',
    'Teal',
    'Lime',
    'Indigo',
    'Violet',
    'Maroon',
    'Navy',
    'Olive',
    'Silver',
    'Gold',
    'Beige',
    'Coral'
  ];

  @override
  void initState() {
    super.initState();
    _checkUploadLimit();
    if (widget.artworkId != null) {
      _loadArtworkData();
    }
    if (widget.imageFile != null) {
      _mainImageFile = widget.imageFile;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    _materialsController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _tagController.dispose();
    _hashtagController.dispose();
    _keywordController.dispose();
    _creationProcessController.dispose();
    _inspirationController.dispose();
    _techniqueController.dispose();
    super.dispose();
  }

  // Check if user can upload more artwork based on subscription
  Future<void> _checkUploadLimit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's current subscription
      final subscription = await _subscriptionService.getUserSubscription();
      _tierLevel = subscription?.tier ?? SubscriptionTier.starter;

      // Get count of user's existing artwork
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('artwork')
            .where('userId', isEqualTo: userId)
            .get();

        _artworkCount = snapshot.docs.length;

        // Check if user can upload more artwork
        if (_tierLevel == SubscriptionTier.starter && _artworkCount >= 5) {
          _canUpload = false;
        }
      }
    } catch (e) {
      // debugPrint('Error checking upload limit: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load artwork data if editing
  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc =
          await _firestore.collection('artwork').doc(widget.artworkId).get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('enhanced_upload_not_found'.tr())),
          );
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data()!;

      if (mounted) {
        setState(() {
          _titleController.text = (data['title'] ?? '').toString();
          _descriptionController.text = (data['description'] ?? '').toString();
          _dimensionsController.text = (data['dimensions'] ?? '').toString();
          _materialsController.text = (data['materials'] ?? '').toString();
          _locationController.text = (data['location'] ?? '').toString();
          _priceController.text =
              data['price'] != null ? data['price'].toString() : '';
          _yearController.text =
              data['yearCreated'] != null ? data['yearCreated'].toString() : '';
          _imageUrl = data['imageUrl'] as String?;
          _additionalImageUrls =
              (data['additionalImageUrls'] as List<dynamic>? ?? [])
                  .cast<String>();
          _videoUrls =
              (data['videoUrls'] as List<dynamic>? ?? []).cast<String>();
          _audioUrls =
              (data['audioUrls'] as List<dynamic>? ?? []).cast<String>();
          _isForSale = data['isForSale'] as bool? ?? false;
          _medium = (data['medium'] ?? '').toString();
          _styles = (data['styles'] is List
              ? (data['styles'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _tags = (data['tags'] is List
              ? (data['tags'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _hashtags = (data['hashtags'] is List
              ? (data['hashtags'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _keywords = (data['keywords'] is List
              ? (data['keywords'] as List).map((e) => e.toString()).toList()
              : <String>[]);

          // Load new rich metadata
          _dimensionUnit = (data['dimensionUnit'] ?? 'cm').toString();
          _colorPalette = (data['colorPalette'] is List
              ? (data['colorPalette'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _creationProcessController.text =
              (data['creationProcess'] ?? '').toString();
          _inspirationController.text = (data['inspiration'] ?? '').toString();
          _techniqueController.text = (data['technique'] ?? '').toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('enhanced_upload_load_error'
                  .tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Pick main image - let ImagePicker handle permissions automatically
  Future<void> _pickMainImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _mainImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('enhanced_upload_image_error'
                  .tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  Future<void> _pickAdditionalImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _additionalImageFiles.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  // Pick videos
  Future<void> _pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _videoFiles.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  // Pick audio files
  Future<void> _pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _audioFiles.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  // Remove additional image
  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImageFiles.removeAt(index);
    });
  }

  // Remove video
  void _removeVideo(int index) {
    setState(() {
      _videoFiles.removeAt(index);
    });
  }

  // Remove audio file
  void _removeAudioFile(int index) {
    setState(() {
      _audioFiles.removeAt(index);
    });
  }

  // Upload file to Firebase Storage using EnhancedStorageService for images
  Future<String> _uploadFile(File file, String folder) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Use enhanced storage service for image uploads
    if (folder == 'artwork_images') {
      try {
        final enhancedStorage = EnhancedStorageService();
        final uploadResult = await enhancedStorage.uploadImageWithOptimization(
          imageFile: file,
          category: 'artwork',
          generateThumbnail: true,
        );
        return uploadResult['imageUrl']!;
      } catch (e) {
        debugPrint(
            '❌ Enhanced upload failed, falling back to legacy method: $e');
      }
    }

    // Fallback to legacy method for non-images or if enhanced upload fails
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    // Remove the problematic 'new' subdirectory
    final ref = _storage.ref().child('$folder/$userId/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;

    return snapshot.ref.getDownloadURL();
  }

  // Upload all media files
  Future<void> _uploadAllMedia() async {
    // Upload main image
    if (_mainImageFile != null) {
      _imageUrl = await _uploadFile(_mainImageFile!, 'artwork_images');
    }

    // Upload additional images
    for (final file in _additionalImageFiles) {
      final url = await _uploadFile(file, 'artwork_images');
      _additionalImageUrls.add(url);
    }

    // Upload videos
    for (final file in _videoFiles) {
      final url = await _uploadFile(file, 'artwork_videos');
      _videoUrls.add(url);
    }

    // Upload audio files
    for (final file in _audioFiles) {
      final url = await _uploadFile(file, 'artwork_audio');
      _audioUrls.add(url);
    }
  }

  // Save artwork
  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainImageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enhanced_upload_select_main_image'.tr())),
      );
      return;
    }
    if (_medium.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enhanced_upload_select_medium'.tr())),
      );
      return;
    }
    if (_styles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enhanced_upload_select_style'.tr())),
      );
      return;
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload all media files
      await _uploadAllMedia();

      final price = _isForSale && _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text) ?? 0.0
          : 0.0;

      // Create artwork data
      final artworkData = {
        'userId': userId,
        'artistProfileId': userId, // For now, use userId as artistProfileId
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': _imageUrl,
        'additionalImageUrls': _additionalImageUrls,
        'videoUrls': _videoUrls,
        'audioUrls': _audioUrls,
        'medium': _medium,
        'styles': _styles,
        'dimensions': _dimensionsController.text,
        'materials': _materialsController.text,
        'location': _locationController.text,
        'isForSale': _isForSale,
        'isSold': false,
        'price': price,
        'yearCreated': int.tryParse(_yearController.text),
        'tags': _tags,
        'hashtags': _hashtags,
        'keywords': _keywords,

        // New rich metadata
        'dimensionUnit': _dimensionUnit,
        'colorPalette': _colorPalette,
        'creationProcess': _creationProcessController.text,
        'inspiration': _inspirationController.text,
        'technique': _techniqueController.text,

        'isFeatured': false,
        'isPublic': true,
        'viewCount': 0,
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      if (widget.artworkId != null) {
        await _firestore.collection('artwork').doc(widget.artworkId).update({
          ...artworkData,
          'createdAt':
              FieldValue.serverTimestamp(), // Keep original creation date
        });
      } else {
        await _firestore.collection('artwork').add(artworkData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('enhanced_upload_success'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('enhanced_upload_error'
                  .tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {}
    }
  }

  // Add tag
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // Add hashtag
  void _addHashtag() {
    final hashtag = _hashtagController.text.trim();
    if (hashtag.isNotEmpty && !_hashtags.contains(hashtag)) {
      setState(() {
        _hashtags.add(hashtag.startsWith('#') ? hashtag : '#$hashtag');
        _hashtagController.clear();
      });
    }
  }

  // Add keyword
  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  // Remove tag
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Remove hashtag
  void _removeHashtag(String hashtag) {
    setState(() {
      _hashtags.remove(hashtag);
    });
  }

  // Remove keyword
  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: 'enhanced_upload_title'.tr(),
            showLogo: false,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_canUpload && widget.artworkId == null) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: 'enhanced_upload_title'.tr(),
            showLogo: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 72, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    'enhanced_upload_limit_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'enhanced_upload_limit_message'.tr(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, '/artist/subscription');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text('enhanced_upload_upgrade_button'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: widget.artworkId == null
              ? 'enhanced_upload_title'.tr()
              : 'enhanced_upload_title_edit'.tr(),
          showLogo: false,
          showBackButton: true,
        ),
        body: Stepper(
          currentStep: _currentStepIndex,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          onStepTapped: _onStepTapped,
          controlsBuilder: _buildStepperControls,
          steps: [
            Step(
              title: Text('enhanced_upload_step_media'.tr()),
              subtitle: Text('enhanced_upload_step_media_desc'.tr()),
              content: _buildMediaStep(),
              isActive: _currentStepIndex >= 0,
              state: _getStepState(0),
            ),
            Step(
              title: Text('enhanced_upload_step_basic_info'.tr()),
              subtitle: Text('enhanced_upload_step_basic_info_desc'.tr()),
              content: _buildBasicInfoStep(),
              isActive: _currentStepIndex >= 1,
              state: _getStepState(1),
            ),
            Step(
              title: Text('enhanced_upload_step_details'.tr()),
              subtitle: Text('enhanced_upload_step_details_desc'.tr()),
              content: _buildDetailsStep(),
              isActive: _currentStepIndex >= 2,
              state: _getStepState(2),
            ),
            Step(
              title: Text('enhanced_upload_step_pricing'.tr()),
              subtitle: Text('enhanced_upload_step_pricing_desc'.tr()),
              content: _buildPricingStep(),
              isActive: _currentStepIndex >= 3,
              state: _getStepState(3),
            ),
            Step(
              title: Text('enhanced_upload_step_review'.tr()),
              subtitle: Text('enhanced_upload_step_review_desc'.tr()),
              content: _buildReviewStep(),
              isActive: _currentStepIndex >= 4,
              state: _getStepState(4),
            ),
          ],
        ),
      ),
    );
  }

  StepState _getStepState(int stepIndex) {
    if (stepIndex < _currentStepIndex) {
      return StepState.complete;
    } else if (stepIndex == _currentStepIndex) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
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
                child: Text('enhanced_upload_back'.tr()),
              ),
            ),
          if (_currentStepIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStepIndex == 4
                  ? _saveArtwork
                  : details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.primaryGreen,
              ),
              child: Text(
                _currentStepIndex == 4
                    ? 'enhanced_upload_publish'.tr()
                    : 'enhanced_upload_continue'.tr(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _saveDraft,
            child: Text('enhanced_upload_save_draft'.tr()),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStepIndex < 4) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStepIndex += 1;
          _currentStep = UploadStep.values[_currentStepIndex];
        });
      }
    }
  }

  void _onStepCancel() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex -= 1;
        _currentStep = UploadStep.values[_currentStepIndex];
      });
    }
  }

  void _onStepTapped(int stepIndex) {
    if (stepIndex <= _currentStepIndex) {
      setState(() {
        _currentStepIndex = stepIndex;
        _currentStep = UploadStep.values[stepIndex];
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case UploadStep.media:
        return _mainImageFile != null || _imageUrl != null;
      case UploadStep.basicInfo:
        return _formKey.currentState?.validate() ?? false;
      case UploadStep.details:
        return _medium.isNotEmpty && _styles.isNotEmpty;
      case UploadStep.pricing:
        return !_isForSale || (_isForSale && _priceController.text.isNotEmpty);
      case UploadStep.review:
        return true;
    }
  }

  Future<void> _saveDraft() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final draftData = {
        'userId': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'dimensions': _dimensionsController.text,
        'dimensionUnit': _dimensionUnit,
        'materials': _materialsController.text,
        'location': _locationController.text,
        'price': _priceController.text,
        'yearCreated': _yearController.text,
        'medium': _medium,
        'styles': _styles,
        'tags': _tags,
        'hashtags': _hashtags,
        'keywords': _keywords,
        'colorPalette': _colorPalette,
        'creationProcess': _creationProcessController.text,
        'inspiration': _inspirationController.text,
        'technique': _techniqueController.text,
        'isForSale': _isForSale,
        'currentStep': _currentStepIndex,
        'imageUrl': _imageUrl,
        'additionalImageUrls': _additionalImageUrls,
        'videoUrls': _videoUrls,
        'audioUrls': _audioUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.artworkId != null) {
        await _firestore
            .collection('artwork_drafts')
            .doc(widget.artworkId)
            .set(draftData);
      } else {
        await _firestore.collection('artwork_drafts').add(draftData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('enhanced_upload_draft_saved'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('enhanced_upload_draft_save_error'.tr())),
        );
      }
    }
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enhanced_upload_media_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'enhanced_upload_media_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Main Image Section
        _buildMainImageSection(),
        const SizedBox(height: 24),

        // Additional Images Section
        _buildAdditionalImagesSection(),
        const SizedBox(height: 24),

        // Videos Section
        _buildVideosSection(),
        const SizedBox(height: 24),

        // Audio Files Section
        _buildAudioFilesSection(),
      ],
    );
  }

  Widget _buildMainImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enhanced_upload_main_image_title'.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'enhanced_upload_main_image_description'.tr(),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Main Image Display
        if (_mainImageFile != null) ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _mainImageFile!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _mainImageFile!.path.split('/').last,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _mainImageFile = null;
                    _imageUrl = null;
                    _mainImageUploadProgress = 0.0;
                  });
                },
              ),
            ],
          ),
        ] else ...[
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'enhanced_upload_main_image_placeholder'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Upload Progress Indicator
        if (_isUploadingMainImage) ...[
          Column(
            children: [
              LinearProgressIndicator(
                value: _mainImageUploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_mainImageUploadProgress * 100).toInt()}% ${'enhanced_upload_uploading'.tr()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Upload Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploadingMainImage ? null : _pickMainImage,
            icon: _isUploadingMainImage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera),
            label: Text(
              _mainImageFile != null
                  ? 'enhanced_upload_change_image'.tr()
                  : 'enhanced_upload_select_image'.tr(),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Error Message
        if (_mainImageError != null) ...[
          const SizedBox(height: 8),
          Text(
            _mainImageError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'enhanced_upload_basic_info_step_title'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'enhanced_upload_basic_info_step_description'.tr(),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'enhanced_upload_title_label'.tr(),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'enhanced_upload_title_error'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'enhanced_upload_description_label'.tr(),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'enhanced_upload_description_error'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Year and Dimensions
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'enhanced_upload_year_label'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _dimensionsController,
                  decoration: InputDecoration(
                    labelText: 'enhanced_upload_dimensions_label'.tr(),
                    border: const OutlineInputBorder(),
                    suffixText: _dimensionUnit,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _dimensionUnit,
                items: _dimensionUnits.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dimensionUnit = value ?? 'cm';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Materials and Location
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _materialsController,
                  decoration: InputDecoration(
                    labelText: 'enhanced_upload_materials_label'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'enhanced_upload_location_label'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
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
          'enhanced_upload_details_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'enhanced_upload_details_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Media and Styles
        _buildMediaAndStyles(),
        const SizedBox(height: 24),

        // Rich Metadata
        Text(
          'enhanced_upload_rich_metadata_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Creation Process
        TextFormField(
          controller: _creationProcessController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'enhanced_upload_creation_process_label'.tr(),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'enhanced_upload_creation_process_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),

        // Inspiration
        TextFormField(
          controller: _inspirationController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'enhanced_upload_inspiration_label'.tr(),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'enhanced_upload_inspiration_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),

        // Technique
        TextFormField(
          controller: _techniqueController,
          decoration: InputDecoration(
            labelText: 'enhanced_upload_technique_label'.tr(),
            border: const OutlineInputBorder(),
            hintText: 'enhanced_upload_technique_hint'.tr(),
          ),
        ),
        const SizedBox(height: 16),

        // Color Palette
        Text(
          'enhanced_upload_color_palette_label'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableColors.map((color) {
            final isSelected = _colorPalette.contains(color);
            return FilterChip(
              label: Text(color),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _colorPalette.add(color);
                  } else {
                    _colorPalette.remove(color);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Tags, Hashtags, Keywords
        _buildTagsSection(),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enhanced_upload_pricing_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'enhanced_upload_pricing_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // For Sale Toggle
        SwitchListTile(
          title: Text('enhanced_upload_for_sale_label'.tr()),
          subtitle: Text('enhanced_upload_for_sale_description'.tr()),
          value: _isForSale,
          onChanged: (value) {
            setState(() {
              _isForSale = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Price Input
        if (_isForSale)
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'enhanced_upload_price_label'.tr(),
              border: const OutlineInputBorder(),
              prefixText: '\$',
            ),
            validator: (value) {
              if (_isForSale && (value == null || value.isEmpty)) {
                return 'enhanced_upload_price_error'.tr();
              }
              return null;
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
          'enhanced_upload_review_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'enhanced_upload_review_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Preview Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Preview
                if (_mainImageFile != null || _imageUrl != null) ...[
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: _mainImageFile != null
                          ? DecorationImage(
                              image: FileImage(_mainImageFile!),
                              fit: BoxFit.cover,
                            )
                          : ImageUrlValidator.isValidImageUrl(_imageUrl)
                              ? DecorationImage(
                                  image: ImageUrlValidator.safeNetworkImage(
                                      _imageUrl)!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title and Description
                  Text(
                    _titleController.text.isNotEmpty
                        ? _titleController.text
                        : 'enhanced_upload_no_title'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : 'enhanced_upload_no_description'.tr(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Metadata
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (_medium.isNotEmpty)
                        Chip(
                          label: Text(_medium),
                          backgroundColor:
                              ArtbeatColors.primaryGreen.withAlpha(25),
                        ),
                      if (_styles.isNotEmpty)
                        ..._styles.map((style) => Chip(
                              label: Text(style),
                              backgroundColor: Colors.blue.withAlpha(25),
                            )),
                      if (_isForSale && _priceController.text.isNotEmpty)
                        Chip(
                          label: Text('\$${_priceController.text}'),
                          backgroundColor: Colors.green.withAlpha(25),
                        ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'enhanced_upload_additional_images_label'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickAdditionalImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text('enhanced_upload_add_images_button'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_additionalImageFiles.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _additionalImageFiles.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_additionalImageFiles[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeAdditionalImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_additionalImageFiles.isEmpty)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                'enhanced_upload_no_additional_images_text'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'enhanced_upload_videos_label'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickVideos,
              icon: const Icon(Icons.video_library),
              label: Text('enhanced_upload_add_videos_button'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_videoFiles.isNotEmpty)
          Column(
            children: _videoFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.video_file),
                  title: Text(file.path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeVideo(index),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_videoFiles.isEmpty)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                'enhanced_upload_no_videos_text'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'enhanced_upload_audio_label'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickAudioFiles,
              icon: const Icon(Icons.audiotrack),
              label: Text('enhanced_upload_add_audio_button'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_audioFiles.isNotEmpty)
          Column(
            children: _audioFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.audio_file),
                  title: Text(file.path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeAudioFile(index),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_audioFiles.isEmpty)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Text(
                'enhanced_upload_no_audio_text'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaAndStyles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enhanced_upload_media_styles_title'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Medium dropdown
        DropdownButtonFormField<String>(
          initialValue: _medium.isEmpty ? null : _medium,
          decoration: InputDecoration(
            labelText: 'enhanced_upload_medium_label'.tr(),
            filled: true,
            fillColor: ArtbeatColors.backgroundPrimary,
            border: const OutlineInputBorder(),
          ),
          dropdownColor: ArtbeatColors.backgroundPrimary,
          style: const TextStyle(color: Colors.black),
          items: _availableMediums.map((medium) {
            return DropdownMenuItem<String>(
              value: medium,
              child: Text(medium, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _medium = value;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'enhanced_upload_medium_error'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Styles Multi-Select
        Text(
          'enhanced_upload_styles_label'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableStyles.map((style) {
            final isSelected = _styles.contains(style);
            return FilterChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _styles.add(style);
                  } else {
                    _styles.remove(style);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'enhanced_upload_tags_title'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Tags
        _buildTagInput('enhanced_upload_tags_label'.tr(), _tagController, _tags,
            _addTag, _removeTag),
        const SizedBox(height: 16),

        // Hashtags
        _buildTagInput('enhanced_upload_hashtags_label'.tr(),
            _hashtagController, _hashtags, _addHashtag, _removeHashtag),
        const SizedBox(height: 16),

        // Keywords
        _buildTagInput('enhanced_upload_keywords_label'.tr(),
            _keywordController, _keywords, _addKeyword, _removeKeyword),
      ],
    );
  }

  Widget _buildTagInput(
      String label,
      TextEditingController controller,
      List<String> list,
      VoidCallback addFunction,
      void Function(String) removeFunction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Add $label',
                  border: const OutlineInputBorder(),
                  hintText: label == 'Hashtags'
                      ? 'e.g. #art, #painting'
                      : 'e.g. landscape, nature',
                ),
                onEditingComplete: addFunction,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: addFunction,
              icon: const Icon(Icons.add),
              tooltip: 'Add $label',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: list.map((item) {
              return Chip(
                label: Text(item),
                onDeleted: () => removeFunction(item),
              );
            }).toList(),
          ),
      ],
    );
  }
}
