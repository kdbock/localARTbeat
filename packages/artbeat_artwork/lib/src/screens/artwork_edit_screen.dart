import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;

/// Screen for editing existing artwork
class ArtworkEditScreen extends StatefulWidget {
  final String artworkId;
  final ArtworkModel? artwork;

  const ArtworkEditScreen({
    super.key,
    required this.artworkId,
    this.artwork,
  });

  @override
  State<ArtworkEditScreen> createState() => _ArtworkEditScreenState();
}

class _ArtworkEditScreenState extends State<ArtworkEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artworkService = ArtworkService();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagController = TextEditingController();

  // State variables
  ArtworkModel? _artwork;
  File? _newImageFile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isForSale = false;
  bool _isPublic = true;
  String _medium = '';
  List<String> _styles = [];
  List<String> _tags = [];

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
    _loadArtworkData();
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

  /// Load artwork data
  Future<void> _loadArtworkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use provided artwork or fetch from service
      _artwork = widget.artwork ??
          await _artworkService.getArtworkById(widget.artworkId);

      if (_artwork != null) {
        _titleController.text = _artwork!.title;
        _descriptionController.text = _artwork!.description;
        _dimensionsController.text = _artwork!.dimensions ?? '';
        _materialsController.text = _artwork!.materials ?? '';
        _locationController.text = _artwork!.location ?? '';
        _priceController.text = _artwork!.price?.toString() ?? '';
        _yearController.text = _artwork!.yearCreated?.toString() ?? '';

        _isForSale = _artwork!.isForSale;
        _isPublic = _artwork!.isPublic;
        _medium = _artwork!.medium;
        _styles = List<String>.from(_artwork!.styles);
        _tags = List<String>.from(_artwork!.tags ?? []);

        // Set tags in text field
        _tagController.text = _tags.join(', ');
      }
    } catch (e) {
      // debugPrint('Error loading artwork: $e');
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

  /// Pick new image
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _newImageFile = File(image.path);
        });
      }
    } catch (e) {
      // debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('art_walk_error_picking_image'
                  .tr()
                  .replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  /// Save artwork changes
  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse tags
      _tags = _tagController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Update artwork
      await _artworkService.updateArtwork(
        artworkId: widget.artworkId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        medium: _medium,
        styles: _styles,
        tags: _tags,
        dimensions: _dimensionsController.text.trim().isEmpty
            ? null
            : _dimensionsController.text.trim(),
        materials: _materialsController.text.trim().isEmpty
            ? null
            : _materialsController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        price: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        isForSale: _isForSale,
        yearCreated: _yearController.text.trim().isEmpty
            ? null
            : int.tryParse(_yearController.text.trim()),
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('art_walk_artwork_updated_successfully'.tr())),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      // debugPrint('Error updating artwork: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('art_walk_error_updating_artwork'
                  .tr()
                  .replaceAll('{error}', e.toString()))),
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

  /// Delete artwork
  Future<void> _deleteArtwork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('artwork_edit_delete_confirm_title'.tr()),
        content: Text('artwork_edit_delete_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('artwork_edit_delete_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('artwork_edit_delete_confirm_button'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _artworkService.deleteArtwork(widget.artworkId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('art_walk_artwork_deleted_successfully'.tr())),
          );
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        // debugPrint('Error deleting artwork: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('art_walk_error_deleting_artwork'
                    .tr()
                    .replaceAll('{error}', e.toString()))),
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
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'artwork_edit_title'.tr(),
          showLogo: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _artwork == null
                ? Center(child: Text('artwork_edit_not_found'.tr()))
                : _buildEditForm(),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            _buildImageSection(),
            const SizedBox(height: 24),

            // Basic information
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Medium and styles
            _buildMediumAndStylesSection(),
            const SizedBox(height: 24),

            // Additional details
            _buildAdditionalDetailsSection(),
            const SizedBox(height: 24),

            // Tags
            _buildTagsSection(),
            const SizedBox(height: 24),

            // Sale information
            _buildSaleInfoSection(),
            const SizedBox(height: 24),

            // Privacy settings
            _buildPrivacySection(),
            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_image_label'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _newImageFile != null
              ? Image.file(_newImageFile!, fit: BoxFit.cover)
              : _artwork!.imageUrl.isNotEmpty
                  ? SecureNetworkImage(
                      imageUrl: _artwork!.imageUrl,
                      fit: BoxFit.cover,
                      enableThumbnailFallback:
                          true, // Enable fallback for artwork
                      errorWidget:
                          const Icon(Icons.image, size: 64, color: Colors.grey),
                    )
                  : const Icon(Icons.image, size: 64, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library),
          label: Text('artwork_edit_change_image'.tr()),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_basic_info'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_title_label'.tr(),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'artwork_edit_title_error'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_description_label'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'artwork_edit_description_error'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMediumAndStylesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_medium_styles'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _medium.isEmpty ? null : _medium,
          decoration: InputDecoration(
            labelText: 'artwork_edit_medium_label'.tr(),
            border: const OutlineInputBorder(),
          ),
          items: _availableMediums.map((medium) {
            return DropdownMenuItem(
              value: medium,
              child: Text(medium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _medium = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'artwork_edit_medium_error'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text('artwork_edit_styles_label'.tr()),
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

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_additional_details'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dimensionsController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_dimensions_label'.tr(),
            hintText: 'artwork_edit_dimensions_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _materialsController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_materials_label'.tr(),
            hintText: 'artwork_edit_materials_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_location_label'.tr(),
            hintText: 'artwork_edit_location_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _yearController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_year_label'.tr(),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final year = int.tryParse(value);
              if (year == null || year < 1000 || year > DateTime.now().year) {
                return 'artwork_edit_year_error'.tr();
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_tags_label'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tagController,
          decoration: InputDecoration(
            labelText: 'artwork_edit_tags_input'.tr(),
            hintText: 'artwork_edit_tags_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_sale_info'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('artwork_edit_for_sale'.tr()),
          value: _isForSale,
          onChanged: (value) {
            setState(() {
              _isForSale = value;
            });
          },
        ),
        if (_isForSale) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'artwork_edit_price_label'.tr(),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isForSale && (value == null || value.trim().isEmpty)) {
                return 'artwork_edit_price_error_required'.tr();
              }
              if (value != null && value.isNotEmpty) {
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'artwork_edit_price_error_invalid'.tr();
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'artwork_edit_privacy'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('artwork_edit_public_artwork'.tr()),
          subtitle: Text('artwork_edit_public_subtitle'.tr()),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveArtwork,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtbeatColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('artwork_edit_save_button'.tr()),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _deleteArtwork,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('artwork_edit_delete_button'.tr()),
          ),
        ),
      ],
    );
  }
}
