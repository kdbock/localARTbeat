import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

/// Capture details screen with terms checkbox
class CaptureDetailScreen extends StatefulWidget {
  final File imageFile;

  const CaptureDetailScreen({Key? key, required this.imageFile})
    : super(key: key);

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final CaptureService _captureService = CaptureService();
  final StorageService _storageService = StorageService();

  Position? _currentPosition;
  String? _selectedArtType;
  String? _selectedArtMedium;
  bool _hasAcceptedTerms = false;
  bool _isSubmitting = false;

  // Simplified art types list
  static const List<String> _artTypes = [
    'Mural',
    'Street Art',
    'Sculpture',
    'Statue',
    'Graffiti',
    'Monument',
    'Installation',
    'Mosaic',
    'Public Art',
    'Other',
    'I don\'t know',
  ];

  // Simplified art mediums list
  static const List<String> _artMediums = [
    'Paint',
    'Spray Paint',
    'Stone',
    'Metal',
    'Wood',
    'Ceramic',
    'Glass',
    'Mixed Media',
    'Digital',
    'Other',
    'I don\'t know',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      core.AppLogger.error('Error getting location: $e');
    }
  }

  Future<void> _submitCapture() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAcceptedTerms) {
      _showSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload image
      final imageUrl = await _storageService.uploadCaptureImage(
        widget.imageFile,
        FirebaseAuth.instance.currentUser!.uid,
      );

      // Create capture model
      final capture = core.CaptureModel(
        id: '', // Will be set by Firestore
        userId: FirebaseAuth.instance.currentUser!.uid,
        imageUrl: imageUrl,
        title: _titleController.text.trim(),
        artistName: _artistController.text.trim().isEmpty
            ? null
            : _artistController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        artType: _selectedArtType,
        artMedium: _selectedArtMedium,
        location: _currentPosition != null
            ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
        locationName: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdAt: DateTime.now(),
        isPublic: true, // Default to public
      );

      // Save capture
      await _captureService.createCapture(capture);

      if (mounted) {
        _showSnackBar('Capture saved successfully!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      core.AppLogger.error('Error submitting capture: $e');
      if (mounted) {
        _showSnackBar('Error saving capture: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('capture_capture_detail_text_capture_details'.tr()),
        backgroundColor: core.ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.imageFile,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
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
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Artist field
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artist (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Art type dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedArtType,
                decoration: InputDecoration(
                  labelText: 'capture_edit_art_type'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: _artTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedArtType = value),
              ),
              const SizedBox(height: 16),

              // Art medium dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedArtMedium,
                decoration: InputDecoration(
                  labelText: 'capture_edit_medium'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: _artMediums.map((medium) {
                  return DropdownMenuItem(
                    value: medium,
                    child: Text(
                      medium,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedArtMedium = value),
              ),
              const SizedBox(height: 16),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Downtown Park, Main Street',
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Terms checkbox
              CheckboxListTile(
                value: _hasAcceptedTerms,
                onChanged: (value) =>
                    setState(() => _hasAcceptedTerms = value ?? false),
                title: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'I accept the '),
                      TextSpan(
                        text: 'terms and conditions',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/capture/terms');
                          },
                      ),
                    ],
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCapture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: core.ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('capture_capture_detail_text_save_capture'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
