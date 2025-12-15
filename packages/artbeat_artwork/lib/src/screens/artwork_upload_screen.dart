import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_artist/artbeat_artist.dart' show SubscriptionService;
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        ArtbeatColors,
        EnhancedUniversalHeader,
        EnhancedStorageService,
        MainLayout,
        AppLogger,
        ImageUrlValidator;

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
    'Pencil'
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
    'Portrait'
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
              content: Text('artwork_upload_pick_image'
                  .tr(namedArgs: {'error': e.toString()}))),
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
      final doc =
          await _firestore.collection('artwork').doc(widget.artworkId).get();

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
          _priceController.text =
              data['price'] != null ? data['price'].toString() : '';
          _yearController.text =
              data['yearCreated'] != null ? data['yearCreated'].toString() : '';
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
              content: Text('art_walk_error_loading_artwork'
                  .tr()
                  .replaceAll('{error}', e.toString()))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('artwork_upload_no_image'.tr())),
      );
      return;
    }
    if (_medium.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('artwork_upload_no_medium'.tr())),
      );
      return;
    }
    if (_styles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('artwork_upload_no_styles'.tr())),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('artwork_upload_success'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('artwork_upload_error'
                  .tr(namedArgs: {'error': e.toString()}))),
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
          '❌ Enhanced upload failed, falling back to legacy method: $e');

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
    if (_isLoading) {
      return const MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: EnhancedUniversalHeader(
            title: 'Upload Artwork',
            showLogo: false,
          ),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show upgrade prompt if user can't upload more artwork
    if (!_canUpload && widget.artworkId == null) {
      return MainLayout(
        currentIndex: -1,
        child: Scaffold(
          appBar: const EnhancedUniversalHeader(
            title: 'Upload Artwork',
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
                  const Text(
                    'Free Plan Artwork Limit Reached',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You\'ve reached the maximum of 5 artwork pieces for the Artist Basic Plan. '
                    'Upgrade to Artist Pro for unlimited artwork uploads.',
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
                    child: Text('art_walk_upgrade_now'.tr()),
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
            title: widget.artworkId == null ? 'Upload Artwork' : 'Edit Artwork',
            showLogo: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artwork Image
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : ImageUrlValidator.isValidImageUrl(_imageUrl) &&
                                      _isValidImageUrl(_imageUrl)
                                  ? DecorationImage(
                                      image: ImageUrlValidator.safeNetworkImage(
                                          _imageUrl)!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _imageFile == null && _imageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate,
                                      size: 64),
                                  const SizedBox(height: 8),
                                  Text('art_walk_select_image'.tr()),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Year
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medium dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _medium.isEmpty ? null : _medium,
                    decoration: const InputDecoration(
                      labelText: 'Medium',
                      filled: true,
                      fillColor:
                          ArtbeatColors.backgroundPrimary, // match login_screen
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor:
                        ArtbeatColors.backgroundPrimary, // match login_screen
                    style: const TextStyle(color: Colors.black),
                    items: _availableMediums.map((medium) {
                      return DropdownMenuItem<String>(
                        value: medium,
                        child: Text(medium,
                            style: const TextStyle(color: Colors.black)),
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
                        return 'Please select a medium';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Materials
                  TextFormField(
                    controller: _materialsController,
                    decoration: const InputDecoration(
                      labelText: 'Materials Used',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      hintText: 'Where is this artwork displayed/stored?',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Styles Multi-Select
                  const Text(
                    'Styles',
                    style: TextStyle(
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
                  const SizedBox(height: 16),

                  // For Sale switch
                  SwitchListTile(
                    title: Text('art_walk_available_for_sale'.tr()),
                    value: _isForSale,
                    onChanged: (value) {
                      setState(() {
                        _isForSale = value;
                      });
                    },
                  ),

                  // Price if for sale
                  if (_isForSale)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (USD)',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                        validator: (value) {
                          if (_isForSale && (value == null || value.isEmpty)) {
                            return 'Please enter a price';
                          }
                          return null;
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Tags section
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            labelText: 'Add tags',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. landscape, nature',
                          ),
                          onEditingComplete: _addTag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add),
                        tooltip: 'Add tag',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveArtwork,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : Text(
                              widget.artworkId == null
                                  ? 'Upload Artwork'
                                  : 'Save Changes',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ));
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
