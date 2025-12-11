import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/storage_service.dart';
import '../services/capture_service.dart';

// Capture Upload specific colors
class CaptureUploadColors {
  static const Color primaryDeepOrange = Color(0xFFFF5722);
  static const Color primaryDeepOrangeLight = Color(0xFFFF7043);
  static const Color primaryDeepOrangeDark = Color(0xFFD84315);
  static const Color accentTeal = Color(0xFF00BCD4);
  static const Color accentTealLight = Color(0xFF4DD0E1);
  static const Color backgroundGradientStart = Color(0xFFFFF3E0);
  static const Color backgroundGradientEnd = Color(0xFFE8F5E8);
  static const Color cardBackground = Color(0xFFFFFFF8);
  static const Color textPrimary = Color(0xFFBF360C);
  static Color textSecondary = const Color(0xFFFF5722);
}

class CaptureUploadScreen extends StatefulWidget {
  final File imageFile;

  const CaptureUploadScreen({Key? key, required this.imageFile})
    : super(key: key);

  @override
  State<CaptureUploadScreen> createState() => _CaptureUploadScreenState();
}

class _CaptureUploadScreenState extends State<CaptureUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _photographerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final StorageService _storageService = StorageService();
  final CaptureService _captureService = CaptureService();
  final core.UserService _userService = core.UserService();

  bool _uploading = false;
  bool _locationPermissionGranted = false;
  bool _disclaimerAccepted = false;
  Position? _currentPosition;
  String _uploadStatus = '';

  String? _selectedArtType;
  String? _selectedArtMedium;

  // Static lists to ensure they're properly initialized
  static const List<String> _artTypes = [
    'Mural',
    'Street Art',
    'Sculpture',
    'Statue',
    'Graffiti',
    'Monument',
    'Memorial',
    'Fountain',
    'Installation',
    'Mosaic',
    'Public Art',
    'Wall Art',
    'Building Art',
    'Bridge Art',
    'Park Art',
    'Garden Art',
    'Plaza Art',
    'Architecture',
    'Relief',
    'Transit Art',
    'Playground Art',
    'Community Art',
    'Cultural Art',
    'Historical Marker',
    'Signage Art',
    'Other',
    'I don\'t know',
  ];

  static const List<String> _artMediums = [
    'Paint',
    'Spray Paint',
    'Acrylic',
    'Oil Paint',
    'Watercolor',
    'Bronze',
    'Steel',
    'Iron',
    'Aluminum',
    'Copper',
    'Stone',
    'Marble',
    'Granite',
    'Limestone',
    'Concrete',
    'Brick',
    'Wood',
    'Glass',
    'Stained Glass',
    'Ceramic',
    'Tile',
    'Mosaic Tile',
    'Metal',
    'Plaster',
    'Fiberglass',
    'Resin',
    'Mixed Media',
    'Digital/LED',
    'Neon',
    'Chalk',
    'Charcoal',
    'Fabric',
    'Plastic',
    'Vinyl',
    'Paper',
    'Canvas',
    'Other',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    // debugPrint('CaptureUploadScreen: Art types count: ${_artTypes.length}');
    // debugPrint('CaptureUploadScreen: Art mediums count: ${_artMediums.length}');
    // Art types initialization logging removed for production
    _initializeForm();
  }

  void _initializeForm() async {
    // Auto-populate photographer name from current user
    final currentUserModel = await _userService.getCurrentUserModel();
    if (currentUserModel != null && mounted) {
      _photographerController.text = currentUserModel.fullName;
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('capture_capture_upload_text_location_services_are'.tr())),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('capture_capture_upload_text_location_permissions_are'.tr())),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'capture_upload_location_permissions_denied'.tr(),
          ),
        );
      );
      return;
    }

    // Get current location
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {
        _locationPermissionGranted = true;
        _locationController.text =
            'Current Location (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('capture_capture_upload_error_failed_to_get'.tr())));
    }
  }

  void _showSuccessDialog(core.CaptureModel capture) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text('capture_capture_upload_text_art_captured'.tr()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'capture_upload_success_message'.tr(),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CaptureUploadColors.primaryDeepOrange.withAlpha(
                        (0.1 * 255).toInt(),
                      ),
                      CaptureUploadColors.accentTeal.withAlpha(
                        (0.1 * 255).toInt(),
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CaptureUploadColors.accentTeal.withAlpha(
                      (0.3 * 255).toInt(),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.route,
                      color: CaptureUploadColors.primaryDeepOrange,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'capture_upload_ready_create_art_walk'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'capture_upload_turn_captures_into_walk'.tr(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return to previous screen
                // Navigate to dashboard after successful upload
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dashboard',
                  (route) => false, // Remove all previous routes
                );
              },
              child: Text('capture_capture_upload_text_go_to_dashboard'.tr()),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return to previous screen
                // Navigate to create art walk with this capture
                Navigator.pushNamed(
                  context,
                  '/art-walk/create',
                  arguments: {'capture': capture},
                ).then((_) {
                  // After creating art walk, navigate to dashboard
                  Navigator.pushNamedAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                });
              },
              icon: const Icon(Icons.add_location),
              label: Text('art_walk_art_walk_list_text_create_art_walk'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: CaptureUploadColors.primaryDeepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCapture() async {
    core.AppLogger.info('CaptureUpload: Submit button tapped');

    if (!_formKey.currentState!.validate()) {
      core.AppLogger.warning('CaptureUpload: Form validation failed');
      return;
    }

    if (!_disclaimerAccepted) {
      core.AppLogger.warning('CaptureUpload: Disclaimer not accepted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('capture_capture_upload_text_please_accept_the'.tr()),
        ),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // Validate user is logged in
      if (_userService.currentUser?.uid == null) {
        throw Exception('User not logged in');
      }

      setState(() => _uploadStatus = 'Uploading image...');

      // Debug: Print selected values
      // debugPrint('CaptureUpload: Selected art type: $_selectedArtType');
      // debugPrint('CaptureUpload: Selected art medium: $_selectedArtMedium');
      // debugPrint('CaptureUpload: Art types available: ${_artTypes.length}');
      // debugPrint('CaptureUpload: Art mediums available: ${_artMediums.length}');

      // Upload image to storage (should work now with correct bucket)
      final imageUrl = await _storageService.uploadImage(widget.imageFile);

      // Create capture model
      final capture = core.CaptureModel(
        id: '', // Will be set by Firestore
        userId: _userService.currentUser!.uid,
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        artistName: _artistController.text.trim().isEmpty
            ? null
            : _artistController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _currentPosition != null
            ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
        locationName: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        artType: _selectedArtType,
        artMedium: _selectedArtMedium,
        isPublic: true, // Since disclaimer was accepted
        tags: [], // Could be enhanced later
      );

      setState(() => _uploadStatus = 'Saving capture...');
      // Save to database - this now returns immediately after saving to Firestore
      // Background operations (XP, achievements, etc.) will complete asynchronously
      final savedCapture = await _captureService.createCapture(capture);

      if (mounted) {
        // Update status to show completion
        setState(() => _uploadStatus = 'Processing rewards...');

        // Give a brief moment for the status to show, then show success
        await Future<void>.delayed(const Duration(milliseconds: 300));

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'capture_upload_upload_success'.tr(),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          );
        );

        // Show success dialog with Create Art Walk option
        _showSuccessDialog(savedCapture);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Upload failed';

        if (e.toString().contains('Failed to upload image')) {
          errorMessage =
              'Failed to upload image. Please check your internet connection.';
        } else if (e.toString().contains('User not logged in')) {
          errorMessage = 'Please log in to upload captures.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Permission denied. Please check your account permissions.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else {
          errorMessage = 'Upload failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: core.EnhancedUniversalHeader(
        title: 'Upload Capture',
        showLogo: false,
        showBackButton: true,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: _uploading ? null : _submitCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: core.ArtbeatColors.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _uploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _uploadStatus.isEmpty
                              ? 'capture_upload_uploading'.tr()
                              : _uploadStatus,
                        ),
                      ],
                    )
                  : Text('capture_capture_upload_text_submit'.tr()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              core.ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              Colors.pink.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image preview
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(widget.imageFile, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Artist field
                    TextFormField(
                      controller: _artistController,
                      decoration: const InputDecoration(
                        labelText: 'Artist',
                        border: OutlineInputBorder(),
                        hintText: 'Leave blank if unknown',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photographer field (auto-populated)
                    TextFormField(
                      controller: _photographerController,
                      decoration: const InputDecoration(
                        labelText: 'Photographer',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Location field with button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _uploading
                              ? null
                              : _requestLocationPermission,
                          icon: Icon(
                            _locationPermissionGranted
                                ? Icons.check
                                : Icons.location_on,
                          ),
                          label: Text(
                            _locationPermissionGranted
                                ? 'capture_upload_located'.tr()
                                : 'capture_upload_get_location'.tr(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Art Type dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedArtType,
                      decoration: const InputDecoration(
                        labelText: 'Art Type',
                        filled: true,
                        fillColor: core
                            .ArtbeatColors
                            .backgroundPrimary, // match login_screen
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: core
                          .ArtbeatColors
                          .backgroundPrimary, // match login_screen
                      style: const TextStyle(
                        color: core.ArtbeatColors.textPrimary,
                      ),
                      isExpanded: true,
                      items: _artTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: core.ArtbeatColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedArtType = value;
                        });
                      },
                      hint: Text(
                        'capture_upload_select_art_type'.tr(),
                        style: TextStyle(color: core.ArtbeatColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Art Medium dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedArtMedium,
                      decoration: const InputDecoration(
                        labelText: 'Art Medium',
                        filled: true,
                        fillColor: core
                            .ArtbeatColors
                            .backgroundPrimary, // match login_screen
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: core
                          .ArtbeatColors
                          .backgroundPrimary, // match login_screen
                      style: const TextStyle(
                        color: core.ArtbeatColors.textPrimary,
                      ),
                      isExpanded: true,
                      items: _artMediums.map((String medium) {
                        return DropdownMenuItem<String>(
                          value: medium,
                          child: Text(
                            medium,
                            style: const TextStyle(
                              color: core.ArtbeatColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedArtMedium = value;
                        });
                      },
                      hint: Text(
                        'capture_upload_select_art_medium'.tr(),
                        style: TextStyle(color: core.ArtbeatColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Describe the artwork...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Disclaimer checkbox
                    CheckboxListTile(
                      value: _disclaimerAccepted,
                      onChanged: (value) {
                        setState(() => _disclaimerAccepted = value ?? false);
                      },
                      title: Text('capture_capture_upload_text_public_art_disclaimer'.tr()),
                      subtitle: const Text(
                        'I confirm this is public art in a safe, accessible location. No private property, unsafe areas, nudity, or derogatory content.',
                        style: TextStyle(fontSize: 12),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    GestureDetector(
                      onTap: _uploading
                          ? null
                          : () {
                              core.AppLogger.debug(
                                'DEBUG: GestureDetector tapped!',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('capture_capture_upload_button_gesturedetector_was_tapped'.tr()),
                                ),
                              );
                              _submitCapture();
                            },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _uploading
                              ? Colors.grey
                              : core.ArtbeatColors.primaryPurple,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ), // Debug visual
                        ),
                        child: Center(
                          child: _uploading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _uploadStatus.isEmpty
                                          ? 'Uploading...'
                                          : _uploadStatus,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Submit Capture',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Upload overlay
            if (_uploading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _uploadStatus.isEmpty
                                ? 'Uploading...'
                                : _uploadStatus,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please wait while we upload your capture',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _photographerController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
