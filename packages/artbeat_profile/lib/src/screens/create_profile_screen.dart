import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_auth/artbeat_auth.dart' show AuthRoutes;
import 'dart:io';

/// Initial profile creation screen for new users who have authenticated
/// but don't have a profile document in Firestore yet
class CreateProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onProfileCreated;

  const CreateProfileScreen({
    super.key,
    required this.userId,
    this.onProfileCreated,
  });

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  File? _profileImage;
  bool _isSaving = false;
  String? _errorMessage;

  final _userService = UserService();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    // In test environment, don't access Firebase directly
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      currentUser = FirebaseAuth.instance.currentUser;
    }
    _prefillUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Pre-fill form with any available Firebase Auth data
  void _prefillUserData() {
    if (currentUser != null) {
      if (currentUser!.displayName != null) {
        _nameController.text = currentUser!.displayName!;
      }

      // Try to generate a username from email or display name
      if (currentUser!.email != null) {
        final emailPrefix = currentUser!.email!.split('@').first;
        _usernameController.text = emailPrefix.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '',
        );
      }
    }
  }

  /// Handle profile image selection
  Future<void> _selectProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: ${e.toString()}');
    }
  }

  /// Handle profile creation
  Future<void> _handleCreateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Create the user profile
      await _userService.createNewUser(
        uid: widget.userId,
        email: currentUser?.email ?? '',
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
      );

      // Upload profile image if selected
      if (_profileImage != null) {
        try {
          await _userService.updateUserProfileImage(
            widget.userId,
            _profileImage!,
          );
        } catch (e) {
          // debugPrint('⚠️ Profile created but image upload failed: $e');
          // Don't fail the entire process for image upload failure
        }
      }

      if (mounted) {
        // Call the callback if provided
        widget.onProfileCreated?.call();

        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed(AuthRoutes.dashboard);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create profile: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: ArtbeatColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Create Your Profile',
        showLogo: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withAlpha(13),
              Colors.white,
              ArtbeatColors.primaryGreen.withAlpha(13),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        // Welcome message
                        Text(
                          'Welcome to ARTbeat!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Let\'s set up your profile to get started',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: ArtbeatColors.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // Profile image section
                        Center(
                          child: GestureDetector(
                            onTap: _selectProfileImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ArtbeatColors.primaryPurple.withAlpha(
                                  26,
                                ),
                                border: Border.all(
                                  color: ArtbeatColors.primaryPurple,
                                  width: 2,
                                ),
                              ),
                              child: _profileImage != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _profileImage!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: ArtbeatColors.primaryPurple,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add profile photo (optional)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ArtbeatColors.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: ArtbeatColors.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: ArtbeatColors.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: ArtbeatColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Form fields
                        ArtbeatInput(
                          controller: _nameController,
                          label: 'profile_display_name'.tr(),
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your display name';
                            }
                            if (value.trim().length < 2) {
                              return 'Display name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        ArtbeatInput(
                          controller: _usernameController,
                          label: 'profile_username'.tr(),
                          prefixIcon: const Icon(Icons.alternate_email),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9_]+$',
                            ).hasMatch(value.trim())) {
                              return 'Username can only contain letters, numbers, and underscores';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        ArtbeatInput(
                          controller: _bioController,
                          label: 'profile_bio'.tr(),
                          prefixIcon: const Icon(Icons.info_outline),
                          hint: 'profile_bio_hint'.tr(),
                          maxLines: 4,
                          validator: (value) {
                            if (value != null && value.length > 500) {
                              return 'Bio must be less than 500 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        ArtbeatInput(
                          controller: _locationController,
                          label: 'profile_location'.tr(),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          validator: (value) {
                            if (value != null && value.length > 100) {
                              return 'Location must be less than 100 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Create Profile button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleCreateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Create Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
