import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../services/subscription_service.dart' as artist_service;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Screen for creating or editing an artist profile
class ArtistProfileEditScreen extends StatefulWidget {
  final String? artistProfileId;

  const ArtistProfileEditScreen({
    super.key,
    this.artistProfileId,
  });

  @override
  State<ArtistProfileEditScreen> createState() =>
      _ArtistProfileEditScreenState();
}

class _ArtistProfileEditScreenState extends State<ArtistProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subscriptionService = artist_service.SubscriptionService();
  final _auth = FirebaseAuth.instance;
  final _enhancedStorage = core.EnhancedStorageService();

  // Text controllers
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _etsyController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isSaving = false;
  core.ArtistProfileModel? _artistProfile;
  core.UserType _userType = core.UserType.artist;
  List<String> _selectedMediums = [];
  List<String> _selectedStyles = [];
  File? _profileImageFile;
  File? _coverImageFile;
  String? _profileImageUrl;
  String? _coverImageUrl;

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
    _loadArtistProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _etsyController.dispose();
    super.dispose();
  }

  // Load existing profile if editing
  Future<void> _loadArtistProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      core.ArtistProfileModel? artistProfile;

      if (widget.artistProfileId != null) {
        // Load specific profile by ID (for admin editing)
        artistProfile = await _subscriptionService
            .getArtistProfileById(widget.artistProfileId!);
      } else {
        // Load current user's profile (most common case)
        artistProfile = await _subscriptionService.getCurrentArtistProfile();
      }

      if (artistProfile != null && mounted) {
        setState(() {
          _artistProfile = artistProfile;
          _displayNameController.text = artistProfile!.displayName;
          _bioController.text = artistProfile.bio ?? '';

          // Get social links from the socialLinks map
          final socialLinks = artistProfile.socialLinks;
          _websiteController.text = socialLinks['website'] ?? '';
          _instagramController.text = socialLinks['instagram'] ?? '';
          _facebookController.text = socialLinks['facebook'] ?? '';
          _twitterController.text = socialLinks['twitter'] ?? '';
          _etsyController.text = socialLinks['etsy'] ?? '';

          _locationController.text = artistProfile.location ?? '';
          _selectedMediums = List<String>.from(artistProfile.mediums);
          _selectedStyles = List<String>.from(artistProfile.styles);
          _userType = artistProfile.userType;
          _profileImageUrl = artistProfile.profileImageUrl;
          _coverImageUrl = artistProfile.coverImageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'artist_artist_profile_edit_error_error_loading_profile'
                      .tr())),
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

  // Save artist profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload images if changed
      if (_profileImageFile != null) {
        _profileImageUrl = await _uploadImage(_profileImageFile!, 'profile');
      }

      if (_coverImageFile != null) {
        _coverImageUrl = await _uploadImage(_coverImageFile!, 'cover');
      }

      // Save profile
      await _subscriptionService.saveArtistProfile(
        profileId: _artistProfile?.id,
        displayName: _displayNameController.text,
        bio: _bioController.text,
        mediums: _selectedMediums,
        styles: _selectedStyles,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        websiteUrl:
            _websiteController.text.isEmpty ? null : _websiteController.text,
        instagram: _instagramController.text.isEmpty
            ? null
            : _instagramController.text,
        facebook:
            _facebookController.text.isEmpty ? null : _facebookController.text,
        twitter:
            _twitterController.text.isEmpty ? null : _twitterController.text,
        etsy: _etsyController.text.isEmpty ? null : _etsyController.text,
        userType: _userType,
        profileImageUrl: _profileImageUrl,
        coverImageUrl: _coverImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'artist_artist_profile_edit_success_artist_profile_saved'
                      .tr())),
        );
        // Navigate to main dashboard after successful profile creation
        // The dashboard will detect the user is an artist and show appropriate content
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'artist_artist_profile_edit_error_error_saving_profile'
                      .tr())),
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

  // Upload image to Firebase Storage with optimization
  Future<String> _uploadImage(File imageFile, String type) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // debugPrint('🎨 Uploading $type image with optimization...');

    final result = await _enhancedStorage.uploadImageWithOptimization(
      imageFile: imageFile,
      category: type == 'profile' ? 'profile' : 'artwork',
      generateThumbnail: true,
    );

    // debugPrint('✅ $type image uploaded successfully');
    // debugPrint('📊 Original: ${result['originalSize']}');
    // debugPrint('📊 Compressed: ${result['compressedSize']}');

    return result['imageUrl']!;
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  // Pick cover image
  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1, // Artist profile editing doesn't use bottom navigation
      appBar: core.EnhancedUniversalHeader(
        title: _artistProfile == null
            ? 'Create Artist Profile'
            : 'Edit Artist Profile',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: false,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account type selection
                    const Text('art_walk_account_type'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<core.UserType>(
                      segments: [
                        ButtonSegment(
                          value: core.UserType.artist,
                          label: Text(
                              'artist_artist_profile_edit_text_individual_artist'
                                  .tr()),
                          icon: const Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: core.UserType.gallery,
                          label: Text('artist_artist_browse_text_gallery'.tr()),
                          icon: const Icon(Icons.store),
                        ),
                      ],
                      selected: {_userType},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _userType = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Profile images
                    const Text(
                      'Profile Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                  'artist_artist_profile_edit_text_profile_image'
                                      .tr()),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickProfileImage,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                    image: _profileImageFile != null
                                        ? DecorationImage(
                                            image:
                                                FileImage(_profileImageFile!),
                                            fit: BoxFit.cover,
                                          )
                                        : _profileImageUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    _profileImageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: _profileImageFile == null &&
                                          _profileImageUrl == null
                                      ? const Icon(Icons.add_a_photo, size: 40)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('artist_artist_profile_edit_text_cover_image'
                                  .tr()),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickCoverImage,
                                child: Container(
                                  width: 160,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    image: _coverImageFile != null
                                        ? DecorationImage(
                                            image: FileImage(_coverImageFile!),
                                            fit: BoxFit.cover,
                                          )
                                        : _coverImageUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    _coverImageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: _coverImageFile == null &&
                                          _coverImageUrl == null
                                      ? const Icon(Icons.add_photo_alternate,
                                          size: 40)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Basic info
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Art information
                    const Text('art_walk_art_information'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mediums
                    Text('artist_artist_profile_edit_text_mediums'.tr()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _availableMediums.map((medium) {
                        final isSelected = _selectedMediums.contains(medium);
                        return FilterChip(
                          label: Text(medium),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMediums.add(medium);
                              } else {
                                _selectedMediums.remove(medium);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    if (_selectedMediums.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('art_walk_please_select_at_least_one_medium'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Styles
                    Text('artist_artist_profile_edit_text_styles'.tr()),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _availableStyles.map((style) {
                        final isSelected = _selectedStyles.contains(style);
                        return FilterChip(
                          label: Text(style),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedStyles.add(style);
                              } else {
                                _selectedStyles.remove(style);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    if (_selectedStyles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('art_walk_please_select_at_least_one_style'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Online presence
                    const Text('art_walk_online_presence'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.camera_alt),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _facebookController,
                      decoration: const InputDecoration(
                        labelText: 'Facebook',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.facebook),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(
                        labelText: 'Twitter',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _etsyController,
                      decoration: const InputDecoration(
                        labelText: 'Etsy Shop',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ||
                                  _selectedMediums.isEmpty ||
                                  _selectedStyles.isEmpty
                              ? null
                              : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : Text(
                                  _artistProfile == null
                                      ? 'Create Artist Profile'
                                      : 'Save Changes',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
