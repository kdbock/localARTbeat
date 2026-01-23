import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/artist_onboarding/artist_onboarding_data.dart';
import '../../theme/design_system.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'onboarding_widgets.dart';

/// Screen 4: Artwork Upload
///
/// Features:
/// - Grid of upload slots (3x2, expandable)
/// - Per-artwork details modal
/// - For-sale toggle with pricing
/// - Photography tips (collapsible)
/// - Batch upload support
/// - Progress encouragement
class ArtworkUploadScreen extends StatefulWidget {
  const ArtworkUploadScreen({super.key});

  @override
  State<ArtworkUploadScreen> createState() => _ArtworkUploadScreenState();
}

class _ArtworkUploadScreenState extends State<ArtworkUploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _showTips = false;
  bool _hasShownEncouragement = false;

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        final viewModel = context.read<ArtistOnboardingViewModel>();

        for (final image in images) {
          final artworkId = viewModel.addArtwork(localImagePath: image.path);

          // Show details modal for first image
          if (images.indexOf(image) == 0 && mounted) {
            await _showArtworkDetailsModal(artworkId);
          }
        }

        // Show encouragement after 3 artworks
        if (viewModel.data.artworks.length >= 3 && !_hasShownEncouragement) {
          _showEncouragementMessage();
          _hasShownEncouragement = true;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  Future<void> _pickSingleImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        final viewModel = context.read<ArtistOnboardingViewModel>();
        final artworkId = viewModel.addArtwork(localImagePath: image.path);

        if (mounted) {
          await _showArtworkDetailsModal(artworkId);
        }

        if (viewModel.data.artworks.length >= 3 && !_hasShownEncouragement) {
          _showEncouragementMessage();
          _hasShownEncouragement = true;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        final viewModel = context.read<ArtistOnboardingViewModel>();
        final artworkId = viewModel.addArtwork(localImagePath: image.path);

        if (mounted) {
          await _showArtworkDetailsModal(artworkId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
      }
    }
  }

  void _showEncouragementMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Color(0xFF00F5FF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Great start! Profiles with 3+ artworks get 5x more engagement',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00F5FF).withValues(alpha: 0.2),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _showArtworkDetailsModal(String artworkId) async {
    final viewModel = context.read<ArtistOnboardingViewModel>();
    final artwork = viewModel.data.artworks.firstWhere(
      (a) => a.id == artworkId,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArtworkDetailsModal(
        artwork: artwork,
        onSave: (updatedArtwork) {
          viewModel.updateArtwork(artworkId, updatedArtwork);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistOnboardingViewModel>(
      builder: (context, viewModel, child) {
        final artworks = viewModel.data.artworks;
        final canProceed = artworks.isNotEmpty;

        return OnboardingScaffold(
          currentStep: 3,
          canProceed: canProceed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingHeader(
                title: "Let's See Your Beautiful Work!",
                subtitle:
                    'Upload examples of your artwork. You can add more later.',
              ),

              // Progress indicator
              if (artworks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${artworks.length} artwork${artworks.length == 1 ? '' : 's'} uploaded',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF00F5FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Upload buttons
              _buildUploadButtons(),

              const SizedBox(height: 24),

              // Artwork grid
              if (artworks.isNotEmpty) ...[
                _buildArtworkGrid(artworks),
                const SizedBox(height: 24),
              ],

              // Photography tips
              _buildPhotographyTips(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadButtons() {
    return Column(
      children: [
        // Primary: Choose from gallery
        SizedBox(
          width: double.infinity,
          child: OnboardingButton(
            text: 'Choose from Gallery',
            icon: Icons.photo_library,
            onPressed: _pickImages,
          ),
        ),

        const SizedBox(height: 12),

        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: HudButton.secondary(
                text: 'Take Photo',
                icon: Icons.camera_alt,
                onPressed: _takePhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HudButton.secondary(
                text: 'Add One',
                icon: Icons.add_photo_alternate,
                onPressed: _pickSingleImage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArtworkGrid(List<ArtworkDraft> artworks) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        return _buildArtworkTile(artwork);
      },
    );
  }

  Widget _buildArtworkTile(ArtworkDraft artwork) {
    return GestureDetector(
      onTap: () => _showArtworkDetailsModal(artwork.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: artwork.localImagePath != null
                  ? Image.file(
                      File(artwork.localImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Handle file not found error
                        return Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white38,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Image not found',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.image, color: Colors.white38),
                    ),
            ),

            // Edit indicator
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),

            // For sale badge
            if (artwork.isForSale)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'For Sale',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotographyTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudButton.secondary(
          text: _showTips ? 'Hide Tips' : 'Photography Tips',
          icon: _showTips ? Icons.expand_less : Icons.expand_more,
          onPressed: () {
            setState(() => _showTips = !_showTips);
          },
        ),

        if (_showTips) ...[
          const SizedBox(height: 12),
          _buildTipItem('📸', 'Use natural light against a neutral background'),
          _buildTipItem('📏', 'Capture the full artwork with minimal shadows'),
          _buildTipItem('🔲', 'Square or vertical photos work best'),
          _buildTipItem('✨', 'Clean the lens and hold steady'),
        ],
      ],
    );
  }

  Widget _buildTipItem(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal for editing artwork details
class ArtworkDetailsModal extends StatefulWidget {
  final ArtworkDraft artwork;
  final void Function(ArtworkDraft) onSave;

  const ArtworkDetailsModal({
    super.key,
    required this.artwork,
    required this.onSave,
  });

  @override
  State<ArtworkDetailsModal> createState() => _ArtworkDetailsModalState();
}

class _ArtworkDetailsModalState extends State<ArtworkDetailsModal> {
  late TextEditingController _titleController;
  late TextEditingController _yearController;
  late TextEditingController _priceController;
  late TextEditingController _dimensionsController;

  late bool _isForSale;
  String _selectedMedium = 'Painting';
  String _selectedAvailability = 'original';
  String _selectedShipping = 'both';

  final List<String> _mediums = [
    'Painting',
    'Photography',
    'Sculpture',
    'Digital Art',
    'Mixed Media',
    'Drawing',
    'Printmaking',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.artwork.title);
    _yearController = TextEditingController(
      text: widget.artwork.yearCreated?.toString(),
    );
    _priceController = TextEditingController(
      text: widget.artwork.price?.toString(),
    );
    _dimensionsController = TextEditingController(
      text: widget.artwork.dimensions,
    );

    _isForSale = widget.artwork.isForSale;
    _selectedMedium = widget.artwork.medium ?? 'Painting';
    _selectedAvailability = widget.artwork.availability ?? 'original';
    _selectedShipping = widget.artwork.shipping ?? 'both';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedArtwork = widget.artwork.copyWith(
      title: _titleController.text,
      yearCreated: int.tryParse(_yearController.text),
      medium: _selectedMedium,
      isForSale: _isForSale,
      price: _isForSale ? double.tryParse(_priceController.text) : null,
      dimensions: _dimensionsController.text,
      availability: _isForSale ? _selectedAvailability : null,
      shipping: _isForSale ? _selectedShipping : null,
    );

    widget.onSave(updatedArtwork);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Artwork Details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title (required)
            OnboardingTextField(
              label: 'Artwork Title *',
              hint: 'e.g., Sunset Over Mountains',
              controller: _titleController,
              showCounter: false,
            ),

            const SizedBox(height: 16),

            // Year and Medium row
            Row(
              children: [
                Expanded(
                  child: OnboardingTextField(
                    label: 'Year Created',
                    hint: DateTime.now().year.toString(),
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    showCounter: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medium',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMedium,
                        dropdownColor: const Color(0xFF0A0E27),
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        items: _mediums.map((medium) {
                          return DropdownMenuItem(
                            value: medium,
                            child: Text(medium),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMedium = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // For Sale toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isForSale
                      ? const Color(0xFF00F5FF)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This artwork is for sale',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (!_isForSale)
                          Text(
                            'Portfolio piece only',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isForSale,
                    onChanged: (value) => setState(() => _isForSale = value),
                    activeThumbColor: const Color(0xFF00F5FF),
                  ),
                ],
              ),
            ),

            // For sale details
            if (_isForSale) ...[
              const SizedBox(height: 16),

              OnboardingTextField(
                label: 'Price (USD)',
                hint: '500',
                controller: _priceController,
                keyboardType: TextInputType.number,
                showCounter: false,
              ),

              const SizedBox(height: 16),

              OnboardingTextField(
                label: 'Dimensions (H x W x D)',
                hint: '24 x 36 inches',
                controller: _dimensionsController,
                showCounter: false,
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            OnboardingButton(text: 'Save Artwork', onPressed: _save),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
