import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        ArtbeatColors,
        GlassCard,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        WorldBackground;
import 'audio_content_upload_screen.dart';
import 'video_content_upload_screen.dart';

class UploadChoiceScreen extends StatelessWidget {
  const UploadChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 2,
      appBar: HudTopBar(
        title: 'upload_choice_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        subtitle: '',
      ),
      child: WorldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  radius: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF7C4DFF),
                              Color(0xFF22D3EE),
                              Color(0xFF34D399),
                            ],
                          ),
                        ),
                        child: Text(
                          'upload_choice_title'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'upload_choice_subtitle'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'upload_choice_subheadline'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientCTAButton(
                        height: 48,
                        width: double.infinity,
                        text: 'upload_choice_primary_cta'.tr(),
                        icon: Icons.add,
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed('/artwork/upload/visual'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                UploadOptionCard(
                  icon: Icons.image_outlined,
                  title: 'upload_choice_visual_title'.tr(),
                  description: 'upload_choice_visual_desc'.tr(),
                  color: ArtbeatColors.primaryGreen,
                  onTap: () {
                    Navigator.of(context).pushNamed('/artwork/upload/visual');
                  },
                ),
                const SizedBox(height: 16),
                UploadOptionCard(
                  icon: Icons.book_outlined,
                  title: 'upload_choice_written_title'.tr(),
                  description: 'upload_choice_written_desc'.tr(),
                  color: const Color(0xFF7C4DFF),
                  onTap: () {
                    Navigator.of(context).pushNamed('/artwork/upload/written');
                  },
                ),
                const SizedBox(height: 16),
                UploadOptionCard(
                  icon: Icons.mic_outlined,
                  title: 'upload_choice_audio_title'.tr(),
                  description: 'upload_choice_audio_desc'.tr(),
                  color: const Color(0xFF22D3EE),
                  onTap: () {
                    Navigator.of(context).push<AudioContentUploadScreen>(
                      MaterialPageRoute(
                        builder: (context) => const AudioContentUploadScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                UploadOptionCard(
                  icon: Icons.theaters_outlined,
                  title: 'upload_choice_video_title'.tr(),
                  description: 'upload_choice_video_desc'.tr(),
                  color: const Color(0xFFFF3D8D),
                  onTap: () {
                    Navigator.of(context).push<VideoContentUploadScreen>(
                      MaterialPageRoute(
                        builder: (context) => const VideoContentUploadScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UploadOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const UploadOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      showAccentGlow: true,
      accentColor: color,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, const Color(0xFF22D3EE)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 22,
          ),
        ],
      ),
    );
  }
}
