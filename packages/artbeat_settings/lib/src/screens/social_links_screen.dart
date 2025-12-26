import 'package:flutter/material.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/hud_button.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();
  final youtubeController = TextEditingController();
  final websiteController = TextEditingController();
  bool isSaving = false;

  Future<void> _saveLinks() async {
    setState(() => isSaving = true);

    await Future<void>.delayed(
      const Duration(seconds: 1),
    ); // simulate network call

    if (!mounted) return;
    setState(() => isSaving = false);
    Navigator.pop(context); // or show a toast/snackbar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background
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
                  title: 'social_links_title',
                  subtitle: 'social_links_subtitle',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 12, bottom: 36),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SettingsSectionCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 22,
                          ),
                          child: Column(
                            children: [
                              GlassTextField(
                                label: 'Instagram',
                                controller: instagramController,
                                icon: Icons.camera_alt_rounded,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),

                              GlassTextField(
                                label: 'Twitter / X',
                                controller: twitterController,
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),

                              GlassTextField(
                                label: 'YouTube Channel',
                                controller: youtubeController,
                                icon: Icons.video_collection_rounded,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 16),

                              GlassTextField(
                                label: 'Website',
                                controller: websiteController,
                                icon: Icons.link_rounded,
                                keyboardType: TextInputType.url,
                              ),
                              const SizedBox(height: 28),

                              HudButton(
                                label: isSaving ? 'Saving...' : 'Save Links',
                                icon: Icons.save_alt_rounded,
                                onTap: isSaving ? null : _saveLinks,
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
