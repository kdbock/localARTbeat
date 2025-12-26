import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/glass_card.dart';
import '../widgets/hud_button.dart';
import '../widgets/hud_top_bar.dart';

class CaptureViewScreen extends StatelessWidget {
  final File imageFile;
  final String title;
  final String description;

  const CaptureViewScreen({
    super.key,
    required this.imageFile,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // ------------------------
          // BACKGROUND GRADIENT
          // ------------------------
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

          // ------------------------
          // CONTENT
          // ------------------------
          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'capture_view_title'.tr(),
                  subtitle: 'capture_view_subtitle'.tr(),
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
                              // IMAGE PREVIEW
                              // ------------------------
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(
                                  imageFile,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ------------------------
                              // TITLE
                              // ------------------------
                              Text(
                                title,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withAlpha(
                                    (0.95 * 255).toInt(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // ------------------------
                              // DESCRIPTION
                              // ------------------------
                              Text(
                                description,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(
                                    (0.7 * 255).toInt(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ------------------------
                              // ACTION BUTTONS
                              // ------------------------
                              Row(
                                children: [
                                  Expanded(
                                    child: HudButton(
                                      label: 'capture_view_edit'.tr(),
                                      icon: Icons.edit_rounded,
                                      onTap: () => Navigator.pop(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: HudButton(
                                      label: 'capture_view_submit'.tr(),
                                      icon: Icons.cloud_upload_rounded,
                                      onTap: () {
                                        // TODO: Trigger final submit logic
                                        Navigator.popUntil(
                                          context,
                                          (route) => route.isFirst,
                                        );
                                      },
                                    ),
                                  ),
                                ],
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
