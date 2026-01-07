import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import 'package:artbeat_capture/artbeat_capture.dart';


class CaptureEditScreen extends StatefulWidget {
  final CaptureModel capture;

  const CaptureEditScreen({
    super.key,
    required this.capture,
  });

  @override
  State<CaptureEditScreen> createState() => _CaptureEditScreenState();
}

class _CaptureEditScreenState extends State<CaptureEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late File _imageFile;
  bool _isNewImage = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.capture.title);
    _descriptionController = TextEditingController(
      text: widget.capture.description,
    );
    // Placeholder - will be shown using NetworkImage if not new
    _imageFile = File(''); 
  }

  Future<void> _pickNewImage() async {
    final File? result = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (context) => const CaptureScreen(isPicker: true),
      ),
    );

    if (result != null) {
      setState(() {
        _imageFile = result;
        _isNewImage = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('capture_edit_error_title_required'.tr())),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final captureService = CaptureService();
      final updates = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      if (_isNewImage) {
        final storageService = StorageService();
        final newImageUrl = await storageService.uploadCaptureImage(
          _imageFile,
          widget.capture.userId,
        );
        updates['imageUrl'] = newImageUrl;
      }

      await captureService.updateCapture(widget.capture.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('capture_edit_success'.tr())),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('Error saving capture changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('capture_edit_error_generic'.tr())),
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
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // World background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0B1222),
                  Color(0xFF0A1B15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'capture_edit_title'.tr(),
                  subtitle: 'capture_edit_subtitle'.tr(),
                  onBack: () => Navigator.pop(context),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: GlassCard(
                          radius: 26,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              GestureDetector(
                                onTap: _pickNewImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    children: [
                                      _isNewImage 
                                        ? Image.file(
                                            _imageFile,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            widget.capture.imageUrl,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 200,
                                              color: Colors.grey[900],
                                              child: const Icon(Icons.error, color: Colors.white70),
                                            ),
                                          ),
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withAlpha(
                                            (0.3 * 255).toInt(),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'capture_edit_tap_replace'.tr(),
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white.withAlpha(
                                                  (0.9 * 255).toInt(),
                                                ),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Title
                              GlassTextField(
                                label: 'capture_edit_field_title'.tr(),
                                controller: _titleController,
                                icon: Icons.title_rounded,
                              ),

                              const SizedBox(height: 14),

                              // Description
                              GlassTextField(
                                label: 'capture_edit_field_description'.tr(),
                                controller: _descriptionController,
                                icon: Icons.description_rounded,
                                keyboardType: TextInputType.multiline,
                              ),

                              const SizedBox(height: 22),

                              HudButton(
                                label: _isSaving
                                    ? 'capture_edit_saving'.tr()
                                    : 'capture_edit_save'.tr(),
                                icon: Icons.save_rounded,
                                onTap: _isSaving ? () {} : _saveChanges,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
