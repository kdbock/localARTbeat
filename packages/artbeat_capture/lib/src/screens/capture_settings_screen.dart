import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaptureSettingsScreen extends StatefulWidget {
  const CaptureSettingsScreen({super.key});

  @override
  State<CaptureSettingsScreen> createState() => _CaptureSettingsScreenState();
}

class _CaptureSettingsScreenState extends State<CaptureSettingsScreen> {
  static const _locationTagsKey = 'capture_settings_location_tags';
  static const _highQualityUploadsKey = 'capture_settings_high_quality_uploads';
  static const _saveDraftsKey = 'capture_settings_save_drafts';

  bool _locationTagsEnabled = true;
  bool _highQualityUploadsEnabled = true;
  bool _saveDraftsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _locationTagsEnabled = prefs.getBool(_locationTagsKey) ?? true;
      _highQualityUploadsEnabled =
          prefs.getBool(_highQualityUploadsKey) ?? true;
      _saveDraftsEnabled = prefs.getBool(_saveDraftsKey) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    setState(() {
      switch (key) {
        case _locationTagsKey:
          _locationTagsEnabled = value;
          break;
        case _highQualityUploadsKey:
          _highQualityUploadsEnabled = value;
          break;
        case _saveDraftsKey:
          _saveDraftsEnabled = value;
          break;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
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
                  title: 'Capture Settings',
                  subtitle: 'Control how your captures are created and stored',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Capture Preferences',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSwitch(
                                    title: 'Location Tags',
                                    subtitle:
                                        'Attach approximate location metadata to captures.',
                                    value: _locationTagsEnabled,
                                    onChanged: (value) =>
                                        _setBool(_locationTagsKey, value),
                                  ),
                                  _buildSwitch(
                                    title: 'High Quality Uploads',
                                    subtitle:
                                        'Prefer higher image quality over faster upload speed.',
                                    value: _highQualityUploadsEnabled,
                                    onChanged: (value) =>
                                        _setBool(_highQualityUploadsKey, value),
                                  ),
                                  _buildSwitch(
                                    title: 'Save Drafts Automatically',
                                    subtitle:
                                        'Store local drafts if upload is interrupted.',
                                    value: _saveDraftsEnabled,
                                    onChanged: (value) =>
                                        _setBool(_saveDraftsKey, value),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withValues(alpha: 0.74),
          fontSize: 12,
        ),
      ),
      value: value,
      activeThumbColor: const Color(0xFF34D399),
      onChanged: onChanged,
    );
  }
}
