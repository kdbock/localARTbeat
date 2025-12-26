import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/glass_card.dart';

class CaptureDetailScreen extends StatelessWidget {
  final File imageFile;
  final String title;
  final String description;
  final DateTime submittedAt;
  final int xpAwarded;
  final String status;

  const CaptureDetailScreen({
    super.key,
    required this.imageFile,
    required this.title,
    required this.description,
    required this.submittedAt,
    required this.xpAwarded,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = "${submittedAt.toLocal()}".split(' ')[0];

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background gradient
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
                  title: 'capture_detail_title'.tr(),
                  subtitle: 'capture_detail_subtitle'.tr(),
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
                              // Image preview
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(
                                  imageFile,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Title
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

                              // Description
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

                              const SizedBox(height: 20),

                              // Metadata section
                              Divider(
                                color: Colors.white.withAlpha(
                                  (0.1 * 255).toInt(),
                                ),
                              ),
                              const SizedBox(height: 10),

                              _metaRow(
                                label: 'capture_detail_submitted_on'.tr(),
                                value: formattedDate,
                              ),
                              _metaRow(
                                label: 'capture_detail_status'.tr(),
                                value: status,
                              ),
                              _metaRow(
                                label: 'capture_detail_xp_awarded'.tr(),
                                value: '$xpAwarded XP',
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

  Widget _metaRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha((0.75 * 255).toInt()),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha((0.9 * 255).toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
