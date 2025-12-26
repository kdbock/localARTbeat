import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/glass_card.dart';
import '../widgets/hud_top_bar.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/hud_button.dart';

class CaptureEditScreen extends StatefulWidget {
  final File initialImage;
  final String initialTitle;
  final String initialDescription;

  const CaptureEditScreen({
    super.key,
    required this.initialImage,
    required this.initialTitle,
    required this.initialDescription,
  });

  @override
  State<CaptureEditScreen> createState() => _CaptureEditScreenState();
}

class _CaptureEditScreenState extends State<CaptureEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late File _imageFile;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _imageFile = widget.initialImage;
  }

  Future<void> _pickNewImage() async {
    // TODO: Add your camera/gallery service
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
      // TODO: Update capture in backend
      // await CaptureService().update(...);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('capture_edit_error_generic'.tr())),
      );
    } finally {
      setState(() => _isSaving = false);
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
                                      Image.file(
                                        _imageFile,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
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
