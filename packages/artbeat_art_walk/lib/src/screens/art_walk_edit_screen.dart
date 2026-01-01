import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;

/// Screen for editing existing art walks
class ArtWalkEditScreen extends StatefulWidget {
  final String artWalkId;
  final ArtWalkModel? artWalk;

  const ArtWalkEditScreen({super.key, required this.artWalkId, this.artWalk});

  @override
  State<ArtWalkEditScreen> createState() => _ArtWalkEditScreenState();
}

class _ArtWalkEditScreenState extends State<ArtWalkEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ArtWalkService _artWalkService;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _estimatedDistanceController = TextEditingController();

  // State variables
  ArtWalkModel? _artWalk;
  File? _newCoverImage;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPublic = true;
  List<String> _artworkIds = [];

  @override
  void initState() {
    super.initState();
    _artWalkService = context.read<ArtWalkService>();
    _loadArtWalkData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _zipCodeController.dispose();
    _estimatedDurationController.dispose();
    _estimatedDistanceController.dispose();
    super.dispose();
  }

  /// Load art walk data
  Future<void> _loadArtWalkData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use provided art walk or fetch from service
      _artWalk =
          widget.artWalk ??
          await _artWalkService.getArtWalkById(widget.artWalkId);

      if (_artWalk != null) {
        _titleController.text = _artWalk!.title;
        _descriptionController.text = _artWalk!.description;
        _zipCodeController.text = _artWalk!.zipCode ?? '';
        _estimatedDurationController.text =
            _artWalk!.estimatedDuration?.toString() ?? '';
        _estimatedDistanceController.text =
            _artWalk!.estimatedDistance?.toString() ?? '';

        _isPublic = _artWalk!.isPublic;
        _artworkIds = List<String>.from(_artWalk!.artworkIds);
      }
    } catch (e) {
      // debugPrint('Error loading art walk: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_edit_error_error_loading_art'.tr(),
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

  /// Pick new cover image
  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _newCoverImage = File(image.path);
        });
      }
    } catch (e) {
      // debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_edit_error_error_picking_image'.tr(),
            ),
          ),
        );
      }
    }
  }

  /// Save art walk changes including cover image
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update art walk data
      await _artWalkService.updateArtWalk(
        walkId: widget.artWalkId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        estimatedDuration: _estimatedDurationController.text.isNotEmpty
            ? double.parse(_estimatedDurationController.text)
            : null,
        estimatedDistance: _estimatedDistanceController.text.isNotEmpty
            ? double.parse(_estimatedDistanceController.text)
            : null,
        artworkIds: _artworkIds,
        isPublic: _isPublic,
        coverImageFile: _newCoverImage,
      );

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate successful save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_edit_error_error_updating_art'.tr(),
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

  /// Delete art walk
  Future<void> _deleteArtWalk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassCard(
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          title: Text(
            'art_walk_admin_art_walk_moderation_text_delete_art_walk'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          content: Text(
            'art_walk_art_walk_edit_delete_confirmation'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'admin_admin_payment_text_cancel'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'admin_modern_unified_admin_dashboard_text_delete'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: ArtbeatColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _artWalkService.deleteArtWalk(widget.artWalkId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_success_art_walk_deleted'
                    .tr(),
              ),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        // debugPrint('Error deleting art walk: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_error_error_deleting_art'
                    .tr(),
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
  }

  void _handleArtworkSelection(dynamic selectedArtwork) {
    String artworkId;

    if (selectedArtwork is String) {
      artworkId = selectedArtwork;
    } else if (selectedArtwork is Map<String, dynamic>) {
      artworkId =
          (selectedArtwork['id'] ?? selectedArtwork['artworkId'] ?? '')
              as String;
    } else {
      return;
    }

    if (artworkId.isEmpty) {
      return;
    }

    if (_artworkIds.contains(artworkId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_art_walk_edit_text_this_artwork_is'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _artworkIds.add(artworkId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('art_walk_art_walk_edit_success_artwork_added_to'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'art_walk_art_walk_edit_text_edit_art_walk'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: WorldBackground(child: SafeArea(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ArtbeatColors.secondaryTeal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'common_loading'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_artWalk == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'art_walk_art_walk_detail_text_art_walk_not'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_art_walk_edit_error_error_loading_art'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final glassInputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(
        red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
        green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
        blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
        alpha: 0.06 * 255,
      ),
      labelStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(
          red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
          green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
          blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
          alpha: 0.7 * 255,
        ),
        fontWeight: FontWeight.w700,
      ),
      hintStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(
          red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
          green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
          blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
          alpha: 0.45 * 255,
        ),
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(
            red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
            green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
            blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
            alpha: 0.1 * 255,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ArtbeatColors.secondaryTeal),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ArtbeatColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ArtbeatColors.error, width: 2),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCoverImageSection(),
            const SizedBox(height: 24),
            _buildSectionGlassCard(
              title: 'art_walk_art_walk_edit_text_basic_information'.tr(),
              children: [
                _buildFormField(
                  decoration: glassInputDecoration,
                  label: 'art_walk_art_walk_edit_field_title_label'.tr(),
                  controller: _titleController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'art_walk_art_walk_edit_error_title_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  decoration: glassInputDecoration,
                  label: 'art_walk_art_walk_edit_field_description_label'.tr(),
                  controller: _descriptionController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'art_walk_art_walk_edit_error_description_required'
                          .tr();
                    }
                    return null;
                  },
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionGlassCard(
              title: 'art_walk_art_walk_edit_text_location_details'.tr(),
              children: [
                _buildFormField(
                  decoration: glassInputDecoration,
                  label: 'art_walk_art_walk_edit_field_zip_label'.tr(),
                  hint: 'art_walk_art_walk_edit_field_zip_hint'.tr(),
                  controller: _zipCodeController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length != 5 || int.tryParse(value) == null) {
                        return 'art_walk_art_walk_edit_error_zip_invalid'.tr();
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  decoration: glassInputDecoration,
                  label: 'art_walk_art_walk_edit_field_duration_label'.tr(),
                  hint: 'art_walk_art_walk_edit_field_duration_hint'.tr(),
                  controller: _estimatedDurationController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final duration = double.tryParse(value);
                      if (duration == null || duration <= 0) {
                        return 'art_walk_art_walk_edit_error_duration_invalid'
                            .tr();
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  decoration: glassInputDecoration,
                  label: 'art_walk_art_walk_edit_field_distance_label'.tr(),
                  hint: 'art_walk_art_walk_edit_field_distance_hint'.tr(),
                  controller: _estimatedDistanceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final distance = double.tryParse(value);
                      if (distance == null || distance <= 0) {
                        return 'art_walk_art_walk_edit_error_distance_invalid'
                            .tr();
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildArtworkSection(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    final imageWidget = _newCoverImage != null
        ? Image.file(_newCoverImage!, fit: BoxFit.cover)
        : ImageUrlValidator.safeCorrectedNetworkImage(
                _artWalk!.coverImageUrl,
              ) !=
              null
        ? Image(
            image: ImageUrlValidator.safeCorrectedNetworkImage(
              _artWalk!.coverImageUrl,
            )!,
            fit: BoxFit.cover,
          )
        : null;

    return _buildSectionGlassCard(
      title: 'art_walk_art_walk_edit_text_cover_image_label'.tr(),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 224,
            width: double.infinity,
            child: imageWidget ?? _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _pickCoverImage,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text(
              'art_walk_art_walk_edit_text_change_cover_image'.tr(),
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white.withValues(
                red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
                green: (Colors.white.g * 255.0)
                    .round()
                    .clamp(0, 255)
                    .toDouble(),
                blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
                alpha: 0.92 * 255,
              ),
              side: BorderSide(
                color: Colors.white.withValues(
                  red: (Colors.white.r * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  green: (Colors.white.g * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  blue: (Colors.white.b * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  alpha: 0.14 * 255,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkSection() {
    return _buildSectionGlassCard(
      title: 'art_walk_edit_artwork_selection'.tr(),
      children: [
        Text(
          'art_walk_edit_selected_artwork'.tr(
            args: [_artworkIds.length.toString()],
          ),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(
              red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
              green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
              blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
              alpha: 0.92 * 255,
            ),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'art_walk_edit_artwork_selection_hint'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(
              red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
              green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
              blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
              alpha: 0.7 * 255,
            ),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/artwork/browse',
                arguments: {
                  'selectionMode': true,
                  'artWalkId': widget.artWalk?.id,
                  'onArtworkSelected': (String artworkId) {
                    _handleArtworkSelection(artworkId);
                  },
                },
              ).then((selectedArtwork) {
                if (selectedArtwork != null) {
                  _handleArtworkSelection(selectedArtwork);
                }
              });
            },
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'art_walk_art_walk_edit_text_add_artwork'.tr(),
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white.withValues(
                red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
                green: (Colors.white.g * 255.0)
                    .round()
                    .clamp(0, 255)
                    .toDouble(),
                blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
                alpha: 0.92 * 255,
              ),
              side: BorderSide(
                color: Colors.white.withValues(
                  red: (Colors.white.r * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  green: (Colors.white.g * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  blue: (Colors.white.b * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  alpha: 0.14 * 255,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSectionGlassCard(
      title: 'art_walk_edit_privacy_settings'.tr(),
      children: [
        SwitchListTile(
          title: Text(
            'art_walk_art_walk_edit_text_public_art_walk'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(
                red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
                green: (Colors.white.g * 255.0)
                    .round()
                    .clamp(0, 255)
                    .toDouble(),
                blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
                alpha: 0.92 * 255,
              ),
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            'art_walk_art_walk_edit_text_make_this_art'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(
                red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
                green: (Colors.white.g * 255.0)
                    .round()
                    .clamp(0, 255)
                    .toDouble(),
                blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
                alpha: 0.7 * 255,
              ),
            ),
          ),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
            });
          },
          activeThumbColor: ArtbeatColors.secondaryTeal,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GradientCTAButton(
          label: 'admin_admin_user_detail_text_save_changes'.tr(),
          onPressed: _isSaving ? null : _saveChanges,
          loading: _isSaving,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton.icon(
            onPressed: _isSaving ? null : _deleteArtWalk,
            icon: const Icon(Icons.delete_outline, color: ArtbeatColors.error),
            label: Text(
              'art_walk_admin_art_walk_moderation_text_delete_art_walk'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: ArtbeatColors.error,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          red: (Colors.black.r * 255.0).round().clamp(0, 255).toDouble(),
          green: (Colors.black.g * 255.0).round().clamp(0, 255).toDouble(),
          blue: (Colors.black.b * 255.0).round().clamp(0, 255).toDouble(),
          alpha: 0.2 * 255,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white.withValues(
            red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
            green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
            blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
            alpha: 0.45 * 255,
          ),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildSectionGlassCard({
    required String title,
    required List<Widget> children,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white.withValues(
                  red: (Colors.white.r * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  green: (Colors.white.g * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  blue: (Colors.white.b * 255.0)
                      .round()
                      .clamp(0, 255)
                      .toDouble(),
                  alpha: 0.7 * 255,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    String? hint,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    int? maxLines = 1,
    TextInputType? keyboardType,
    required InputDecoration decoration,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(
          red: (Colors.white.r * 255.0).round().clamp(0, 255).toDouble(),
          green: (Colors.white.g * 255.0).round().clamp(0, 255).toDouble(),
          blue: (Colors.white.b * 255.0).round().clamp(0, 255).toDouble(),
          alpha: 0.92 * 255,
        ),
        fontWeight: FontWeight.w600,
      ),
      decoration: decoration.copyWith(labelText: label, hintText: hint),
    );
  }
}
