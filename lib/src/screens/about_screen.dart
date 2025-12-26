import 'package:artbeat_core/artbeat_core.dart' hide PrivacyPolicyScreen, TermsOfServiceScreen;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// About ARTbeat screen displaying app information, version, and credits
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } on Exception catch (e) {
      AppLogger.error('Error loading package info: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // App Logo and Name
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.palette, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 24),

            Text(
              'about_app_name'.tr(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.primaryPurple,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'about_version'.tr(
                namedArgs: {
                  'version': _packageInfo?.version ?? 'Unknown',
                  'buildNumber': _packageInfo?.buildNumber ?? 'Unknown',
                },
              ),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // App Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'about_description'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ArtbeatColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'about_description_text'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features Section
            _buildFeatureSection(),

            const SizedBox(height: 24),

            // Technical Information
            _buildTechnicalInfo(),

            const SizedBox(height: 24),

            // Credits and Legal
            _buildCreditsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'about_features_title'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          Icons.camera_alt,
          'about_feature_art_capture'.tr(),
          'about_feature_art_capture_desc'.tr(),
        ),
        _buildFeatureItem(
          Icons.palette,
          'about_feature_artist_profiles'.tr(),
          'about_feature_artist_profiles_desc'.tr(),
        ),
        _buildFeatureItem(
          Icons.map,
          'about_feature_art_walks'.tr(),
          'about_feature_art_walks_desc'.tr(),
        ),
        _buildFeatureItem(
          Icons.people,
          'about_feature_community'.tr(),
          'about_feature_community_desc'.tr(),
        ),
        _buildFeatureItem(
          Icons.event,
          'about_feature_events'.tr(),
          'about_feature_events_desc'.tr(),
        ),
        _buildFeatureItem(
          Icons.star,
          'about_feature_rewards'.tr(),
          'about_feature_rewards_desc'.tr(),
        ),
      ],
    ),
  );

  Widget _buildFeatureItem(IconData icon, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ArtbeatColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTechnicalInfo() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'about_technical_info'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          'about_app_name_label'.tr(),
          _packageInfo?.appName ?? 'ARTbeat',
        ),
        _buildInfoRow(
          'about_package_name'.tr(),
          _packageInfo?.packageName ?? 'Unknown',
        ),
        _buildInfoRow(
          'about_version_label'.tr(),
          _packageInfo?.version ?? 'Unknown',
        ),
        _buildInfoRow(
          'about_build_number'.tr(),
          _packageInfo?.buildNumber ?? 'Unknown',
        ),
        _buildInfoRow('about_built_with'.tr(), 'about_built_with_value'.tr()),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    ),
  );

  Widget _buildCreditsSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'about_credits_legal'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ArtbeatColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'about_copyright'.tr(),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Text(
          'about_credits_text'.tr(),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
              child: Text('about_privacy_policy'.tr()),
            ),
            const Text(' • '),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const TermsOfServiceScreen(),
                  ),
                );
              },
              child: Text('about_terms_of_service'.tr()),
            ),
          ],
        ),
      ],
    ),
  );
}
