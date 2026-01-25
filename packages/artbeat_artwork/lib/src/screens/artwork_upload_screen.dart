import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_artist/artbeat_artist.dart' show SubscriptionService;
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        EnhancedStorageService,
        MainLayout,
        AppLogger,
        ImageUrlValidator,
        GlassCard,
        GlassInputDecoration,
        GradientCTAButton,
        HudTopBar,
        SecureNetworkImage,
        WorldBackground;

/// Screen for uploading and editing artwork
class ArtworkUploadScreen extends StatefulWidget {
  final String? artworkId; // For editing existing artwork
  final File? imageFile; // For new artwork from capture
  final Position? location; // For location data from capture

  const ArtworkUploadScreen({
    super.key,
    this.artworkId,
    this.imageFile,
    this.location,
  });

  @override
  State<ArtworkUploadScreen> createState() => _ArtworkUploadScreenState();
}

class _ArtworkUploadScreenState extends State<ArtworkUploadScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagController = TextEditingController();

  // Firebase instances
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _subscriptionService = SubscriptionService();

  // State variables
  File? _imageFile;
  String? _imageUrl;
  bool _isForSale = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _canUpload = true;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  String _medium = '';
  List<String> _styles = [];
  List<String> _tags = [];

  // Available options (would typically come from backend)
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
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with passed image file if available
    if (widget.imageFile != null) {
      _imageFile = widget.imageFile;
    }

    // Load existing artwork data if editing
    if (widget.artworkId != null) {
      _loadArtworkData();
    } else {
      // Check upload limits for new artwork
      _checkUploadLimit();
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
    super.dispose();
  }

  // Pick image from gallery - let ImagePicker handle permissions automatically
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artwork_upload_pick_image'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
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
      final doc = await _firestore
          .collection('artwork')
          .doc(widget.artworkId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('art_walk_artwork_not_found'.tr())),
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
          _priceController.text = data['price'] != null
              ? data['price'].toString()
              : '';
          _yearController.text = data['yearCreated'] != null
              ? data['yearCreated'].toString()
              : '';
          _imageUrl = data['imageUrl'] as String?;
          _isForSale = data['isForSale'] as bool? ?? false;
          _medium = (data['medium'] ?? '').toString();
          _styles = (data['styles'] is List
              ? (data['styles'] as List).map((e) => e.toString()).toList()
              : <String>[]);
          _tags = (data['tags'] is List
              ? (data['tags'] as List).map((e) => e.toString()).toList()
              : <String>[]);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_error_loading_artwork'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
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

  // Save artwork
  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('artwork_upload_no_image'.tr())));
      return;
    }
    if (_medium.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('artwork_upload_no_medium'.tr())));
      return;
    }
    if (_styles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('artwork_upload_no_styles'.tr())));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String imageUrl = _imageUrl ?? '';

      // Upload image if changed
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      final price = _isForSale && _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text) ?? 0.0
          : 0.0;

      // Create artwork data
      final artworkData = {
        'userId': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
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
        // For updates, don't overwrite createdAt
        final updateData = Map<String, dynamic>.from(artworkData);
        updateData.remove('createdAt'); // Keep original creation date
        await _firestore
            .collection('artwork')
            .doc(widget.artworkId)
            .update(updateData);
      } else {
        await _firestore.collection('artwork').add(artworkData);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('artwork_upload_success'.tr())));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'artwork_upload_error'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Upload image to Firebase Storage using EnhancedStorageService
  Future<String> _uploadImage(File imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Use the enhanced storage service for optimized uploads
      final enhancedStorage = EnhancedStorageService();
      final uploadResult = await enhancedStorage.uploadImageWithOptimization(
        imageFile: imageFile,
        category: 'artwork',
        generateThumbnail: true,
      );

      return uploadResult['imageUrl']!;
    } catch (e) {
      AppLogger.error(
        '❌ Enhanced upload failed, falling back to legacy method: $e',
      );

      // Fallback to legacy method but with better path structure
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      final ref = _storage.ref().child('artwork_images/$userId/$fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      return snapshot.ref.getDownloadURL();
    }
  }

  // Add tag to the list
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // Remove tag from the list
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      appBar: HudTopBar(
        title: widget.artworkId == null
            ? 'artwork_upload_title'.tr()
            : 'artwork_edit_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                ),
              ),
            ),
        ],
        subtitle: '',
      ),
      child: WorldBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF22D3EE),
                    ),
                  ),
                )
              : (!_canUpload && widget.artworkId == null)
              ? _buildUploadLimitReached()
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildUploadLimitReached() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          radius: 26,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.lock, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'artwork_upload_limit_title'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'artwork_upload_limit_body'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              GradientCTAButton(
                height: 48,
                text: 'art_walk_upgrade_now'.tr(),
                icon: Icons.upgrade,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/artist/subscription',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildBasicInfo(),
            const SizedBox(height: 16),
            _buildMediumAndStyles(),
            const SizedBox(height: 16),
            _buildDetailsSection(),
            const SizedBox(height: 16),
            _buildTagsSection(),
            const SizedBox(height: 16),
            _buildSaleSection(),
            const SizedBox(height: 20),
            GradientCTAButton(
              height: 52,
              width: double.infinity,
              text: _isSaving
                  ? 'artwork_purchase_processing'.tr()
                  : (widget.artworkId == null
                        ? 'artwork_upload_button'.tr()
                        : 'artwork_edit_save_button'.tr()),
              icon: Icons.cloud_upload,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveArtwork,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'artwork_edit_image_label'.tr()),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A1330), Color(0xFF07060F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (_imageUrl != null &&
                          ImageUrlValidator.isValidImageUrl(_imageUrl!) &&
                          _isValidImageUrl(_imageUrl))
                    ? SecureNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        enableThumbnailFallback: true,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'art_walk_select_image'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'artwork_edit_basic_info'.tr()),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_title_label'.tr(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'artwork_edit_title_error'.tr()
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_description_label'.tr(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'artwork_edit_description_error'.tr()
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_year_label'.tr(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumAndStyles() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'artwork_edit_medium_styles'.tr()),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _medium.isEmpty ? null : _medium,
            dropdownColor: const Color(0xFF07060F),
            borderRadius: BorderRadius.circular(16),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_medium_label'.tr(),
            ),
            items: _availableMediums
                .map(
                  (medium) => DropdownMenuItem<String>(
                    value: medium,
                    child: Text(medium),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _medium = value);
              }
            },
            validator: (value) => value == null || value.isEmpty
                ? 'artwork_edit_medium_error'.tr()
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'artwork_edit_styles_label'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStyles.map((style) {
              final isSelected = _styles.contains(style);
              return FilterChip(
                label: Text(
                  style,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
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
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                selectedColor: const Color(0xFF22D3EE).withValues(alpha: 0.28),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'artwork_edit_additional_details'.tr()),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dimensionsController,
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_dimensions_label'.tr(),
              hintText: 'artwork_edit_dimensions_hint'.tr(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _materialsController,
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_materials_label'.tr(),
              hintText: 'artwork_edit_materials_hint'.tr(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: GlassInputDecoration.glass(
              labelText: 'artwork_edit_location_label'.tr(),
              hintText: 'artwork_edit_location_hint'.tr(),
            ),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleSection() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'artwork_edit_sale_info'.tr()),
          const SizedBox(height: 12),
          _GlassSwitchRow(
            label: 'art_walk_available_for_sale'.tr(),
            value: _isForSale,
            onChanged: (value) => setState(() => _isForSale = value),
          ),
          if (_isForSale) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: GlassInputDecoration(
                labelText: 'artwork_edit_price_label'.tr(),
                prefixText: '\$ ',
              ),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              validator: (value) {
                if (_isForSale && (value == null || value.isEmpty)) {
                  return 'artwork_edit_price_error_required'.tr();
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: 'artwork_edit_tags_label'.tr()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  decoration: GlassInputDecoration.glass(
                    labelText: 'artwork_edit_tags_input'.tr(),
                    hintText: 'artwork_edit_tags_hint'.tr(),
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onEditingComplete: _addTag,
                ),
              ),
              const SizedBox(width: 10),
              GlassCard(
                padding: const EdgeInsets.all(12),
                radius: 16,
                glassOpacity: 0.08,
                borderOpacity: 0.18,
                onTap: _addTag,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _tags.map((tag) {
              return GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                radius: 16,
                glassOpacity: 0.08,
                borderOpacity: 0.18,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url.trim().isEmpty) return false;

    // Check for invalid file URLs
    if (url == 'file:///' || url.startsWith('file:///') && url.length <= 8) {
      return false;
    }

    // Check for just the file scheme with no actual path
    if (url == 'file://' || url == 'file:') {
      return false;
    }

    // Check for malformed URLs that start with file:// but have no host
    if (url.startsWith('file://') && !url.startsWith('file:///')) {
      return false;
    }

    // Check for valid URL schemes
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        (url.startsWith('file:///') && url.length > 8);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(alpha: 0.92),
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GlassSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GlassSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF22D3EE),
          ),
        ],
      ),
    );
  }
}
