import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  late final FeedbackService _feedbackService;

  FeedbackType _selectedType = FeedbackType.bug;
  FeedbackPriority _selectedPriority = FeedbackPriority.medium;
  final List<String> _selectedPackages = [
    'general',
  ]; // Changed to support multiple packages
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _feedbackService = context.read<FeedbackService>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('feedback_form_title'.tr()),
        backgroundColor: ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              _buildPackageSelector(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.feedback, color: ArtbeatColors.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'feedback_form_intro_title'.tr(),
                  style: ArtbeatTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'feedback_form_intro_body'.tr(),
              style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'feedback_form_title_label'.tr(),
        hintText: 'feedback_form_title_hint'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'feedback_form_title_error_required'.tr();
        }
        if (value.trim().length < 5) {
          return 'feedback_form_title_error_min_length'.tr();
        }
        return null;
      },
      maxLength: 100,
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'feedback_form_type_label'.tr(),
          style: ArtbeatTypography.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: FeedbackType.values.map((type) {
            return ChoiceChip(
              label: Text(type.displayName),
              selected: _selectedType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
              selectedColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _selectedType == type
                    ? ArtbeatColors.primaryPurple
                    : Colors.grey[700],
                fontWeight: _selectedType == type
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'feedback_form_priority_label'.tr(),
          style: ArtbeatTypography.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: FeedbackPriority.values.map((priority) {
            Color chipColor;
            switch (priority) {
              case FeedbackPriority.low:
                chipColor = Colors.green;
                break;
              case FeedbackPriority.medium:
                chipColor = Colors.orange;
                break;
              case FeedbackPriority.high:
                chipColor = Colors.red;
                break;
              case FeedbackPriority.critical:
                chipColor = Colors.red[800]!;
                break;
            }

            return ChoiceChip(
              label: Text(priority.displayName),
              selected: _selectedPriority == priority,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                }
              },
              selectedColor: chipColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _selectedPriority == priority
                    ? chipColor
                    : Colors.grey[700],
                fontWeight: _selectedPriority == priority
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPackageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'feedback_form_modules_label'.tr(),
          style: ArtbeatTypography.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'feedback_form_modules_hint'.tr(),
          style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackService.getAvailablePackages().map((package) {
            final isSelected = _selectedPackages.contains(package);
            return FilterChip(
              label: Text(_getPackageDisplayName(package)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_selectedPackages.contains(package)) {
                      _selectedPackages.add(package);
                    }
                  } else {
                    _selectedPackages.remove(package);
                  }
                });
              },
              selectedColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
              checkmarkColor: ArtbeatColors.primaryPurple,
              labelStyle: TextStyle(
                color: isSelected
                    ? ArtbeatColors.primaryPurple
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        if (_selectedPackages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'feedback_form_modules_error_required'.tr(),
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'feedback_form_description_label'.tr(),
        hintText: 'feedback_form_description_hint'.tr(),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 6,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'feedback_form_description_error_required'.tr();
        }
        if (value.trim().length < 20) {
          return 'feedback_form_description_error_min_length'.tr();
        }
        return null;
      },
      maxLength: 1000,
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'feedback_form_screenshots_label'.tr(),
          style: ArtbeatTypography.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'feedback_form_screenshots_hint'.tr(),
          style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
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
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedImages.length < 5 ? _pickImages : null,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  _selectedImages.isEmpty
                      ? 'feedback_form_add_screenshots'.tr()
                      : 'feedback_form_add_more_screenshots'.tr(
                          namedArgs: {
                            'count': '${_selectedImages.length}',
                            'max': '5',
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtbeatColors.primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('feedback_form_submitting'.tr()),
                ],
              )
            : Text(
                'feedback_form_title'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  String _getPackageDisplayName(String packageName) {
    final displayNames = {
      'artbeat_core': 'feedback_form_module_artbeat_core'.tr(),
      'artbeat_auth': 'feedback_form_module_artbeat_auth'.tr(),
      'artbeat_profile': 'feedback_form_module_artbeat_profile'.tr(),
      'artbeat_artist': 'feedback_form_module_artbeat_artist'.tr(),
      'artbeat_artwork': 'feedback_form_module_artbeat_artwork'.tr(),
      'artbeat_art_walk': 'feedback_form_module_artbeat_art_walk'.tr(),
      'artbeat_community': 'feedback_form_module_artbeat_community'.tr(),
      'artbeat_capture': 'feedback_form_module_artbeat_capture'.tr(),
      'artbeat_messaging': 'feedback_form_module_artbeat_messaging'.tr(),
      'artbeat_settings': 'feedback_form_module_artbeat_settings'.tr(),
      'artbeat_admin': 'feedback_form_module_artbeat_admin'.tr(),
      'artbeat_ads': 'feedback_form_module_artbeat_ads'.tr(),
      'main_app': 'feedback_form_module_main_app'.tr(),
      'general': 'feedback_form_module_general'.tr(),
    };
    return displayNames[packageName] ?? packageName;
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final pickedFile in pickedFiles) {
            if (_selectedImages.length < 5) {
              _selectedImages.add(File(pickedFile.path));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'feedback_form_images_error'.tr(namedArgs: {'error': '$e'}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least one package is selected
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feedback_form_modules_error_required'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _feedbackService.submitFeedback(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        packageModules: _selectedPackages,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('feedback_form_submit_success'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'feedback_form_submit_error'.tr(namedArgs: {'error': '$e'}),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
