import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/capture_service.dart';

/// Screen for editing capture details
class CaptureEditScreen extends StatefulWidget {
  final core.CaptureModel capture;

  const CaptureEditScreen({Key? key, required this.capture}) : super(key: key);

  @override
  State<CaptureEditScreen> createState() => _CaptureEditScreenState();
}

class _CaptureEditScreenState extends State<CaptureEditScreen> {
  final _captureService = CaptureService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late String _selectedArtType;
  late String _selectedMedium;
  late bool _isPublic;
  bool _isSaving = false;

  // Art type and medium options
  static const artTypes = [
    'Street Art',
    'Graffiti',
    'Mural',
    'Installation',
    'Sculpture',
    'Other',
  ];

  static const mediums = [
    'Acrylic',
    'Oil',
    'Watercolor',
    'Digital',
    'Mixed Media',
    'Spray Paint',
    'Charcoal',
    'Pencil',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.capture.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.capture.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.capture.locationName ?? '',
    );
    _selectedArtType = widget.capture.artType ?? 'Other';
    _selectedMedium = widget.capture.artMedium ?? 'Other';
    _isPublic = widget.capture.isPublic;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'locationName': _locationController.text.trim(),
        'artType': _selectedArtType,
        'artMedium': _selectedMedium,
        'isPublic': _isPublic,
      };

      final success = await _captureService.updateCapture(
        widget.capture.id,
        updates,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_capture_edit_success_capture_updated_successfully'.tr(),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('capture_capture_edit_error_failed_to_update'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      core.AppLogger.error('Error saving capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_detail_error_error_etostring'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('capture_capture_edit_text_edit_capture'.tr()),
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
              // Title
              Text(
                'capture_edit_title'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter capture title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'capture_edit_description'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter capture description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 4,
                maxLines: 6,
              ),

              const SizedBox(height: 24),

              // Location
              Text(
                'capture_edit_location'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter location name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Art Type dropdown
              Text(
                'capture_edit_art_type'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedArtType,
                items: artTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedArtType = value);
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Medium dropdown
              Text(
                'capture_edit_medium'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMedium,
                items: mediums.map((medium) {
                  return DropdownMenuItem(value: medium, child: Text(medium));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMedium = value);
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Visibility toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          color: core.ArtbeatColors.primaryPurple,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isPublic
                              ? 'capture_edit_public'.tr()
                              : 'capture_edit_private'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() => _isPublic = value);
                      },
                      activeThumbColor: core.ArtbeatColors.primaryPurple,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: core.ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : Text(
                          'capture_edit_save_changes'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: Text('admin_admin_payment_text_cancel'.tr()),
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
