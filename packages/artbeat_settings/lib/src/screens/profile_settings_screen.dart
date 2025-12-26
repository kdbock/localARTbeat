import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/hud_top_bar.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/hud_button.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  File? profileImage;
  final nameController = TextEditingController(text: 'Your Name');
  final usernameController = TextEditingController(text: '@username');
  final bioController = TextEditingController(text: 'Short bio or about me...');
  bool isSaving = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    await Future<void>.delayed(const Duration(seconds: 1)); // simulate API call

    if (!mounted) return;
    setState(() => isSaving = false);
    Navigator.pop(context); // or show confirmation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Gradient background
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
                  title: 'profile_settings_title',
                  subtitle: 'profile_settings_subtitle',
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
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  backgroundImage: profileImage != null
                                      ? FileImage(profileImage!)
                                      : null,
                                  child: profileImage == null
                                      ? const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 28,
                                          color: Colors.white70,
                                        )
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 22),

                              GlassTextField(
                                label: 'Display Name',
                                controller: nameController,
                                icon: Icons.person_rounded,
                              ),

                              const SizedBox(height: 16),

                              GlassTextField(
                                label: 'Username',
                                controller: usernameController,
                                icon: Icons.alternate_email_rounded,
                              ),

                              const SizedBox(height: 16),

                              GlassTextField(
                                label: 'Bio',
                                controller: bioController,
                                icon: Icons.info_outline_rounded,
                                keyboardType: TextInputType.multiline,
                              ),

                              const SizedBox(height: 28),

                              HudButton(
                                label: isSaving ? 'Saving...' : 'Save Changes',
                                icon: Icons.save_rounded,
                                onTap: isSaving ? null : _saveProfile,
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
