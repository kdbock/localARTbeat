import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/hud_button.dart';

class CaptureUploadScreen extends StatefulWidget {
  const CaptureUploadScreen({super.key});

  @override
  State<CaptureUploadScreen> createState() => _CaptureUploadScreenState();
}

class _CaptureUploadScreenState extends State<CaptureUploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _selectedImage;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    // TODO integrate your camera/gallery service here.
    // For now just placeholder.
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('capture_upload_error_no_image'.tr())),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('capture_upload_error_title_required'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: Call your capture upload service
      // await CaptureService().upload(...);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('capture_upload_error_generic'.tr())),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // ------------------------
          // WORLD BACKGROUND GRADIENT
          // ------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0A1330),
                  Color(0xFF071C18),
                ],
              ),
            ),
          ),

          // ------------------------
          // CONTENT
          // ------------------------
          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'capture_upload_title'.tr(),
                  subtitle: 'capture_upload_subtitle'.tr(),
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
                              // ------------------------
                              // BADGE
                              // ------------------------
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C4DFF),
                                      Color(0xFF22D3EE),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),

                              const SizedBox(height: 14),

                              Text(
                                'capture_upload_header'.tr(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withAlpha(
                                    (0.95 * 255).toInt(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'capture_upload_description'.tr(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(
                                    (0.70 * 255).toInt(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ------------------------
                              // IMAGE PICKER
                              // ------------------------
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    color: Colors.white.withAlpha(
                                      (0.06 * 255).toInt(),
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(
                                        (0.14 * 255).toInt(),
                                      ),
                                    ),
                                  ),
                                  child: _selectedImage == null
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .add_photo_alternate_rounded,
                                                color: Colors.white70,
                                                size: 36,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'capture_upload_select_image'
                                                    .tr(),
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: Colors.white.withAlpha(
                                                    (0.75 * 255).toInt(),
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ------------------------
                              // TITLE
                              // ------------------------
                              GlassTextField(
                                label: 'capture_upload_field_title'.tr(),
                                controller: _titleController,
                                icon: Icons.title_rounded,
                              ),

                              const SizedBox(height: 14),

                              // ------------------------
                              // DESCRIPTION
                              // ------------------------
                              GlassTextField(
                                label: 'capture_upload_field_description'.tr(),
                                controller: _descriptionController,
                                icon: Icons.description_rounded,
                                keyboardType: TextInputType.multiline,
                              ),

                              const SizedBox(height: 22),

                              HudButton(
                                label: _isSubmitting
                                    ? 'capture_upload_submitting'.tr()
                                    : 'capture_upload_submit'.tr(),
                                icon: Icons.cloud_upload_rounded,
                                onTap: _isSubmitting ? () {} : _submit,
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
