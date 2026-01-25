import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardAppExplanation extends StatelessWidget {
  const DashboardAppExplanation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ArtbeatColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'dashboard_explanation_title'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'dashboard_explanation_subtitle'.tr(),
            style: const TextStyle(
              fontSize: 16,
              color: ArtbeatColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Feature highlights
          _buildFeatureRow(
            icon: Icons.location_on,
            title: 'dashboard_feature_art_title'.tr(),
            description: 'dashboard_feature_art_desc'.tr(),
          ),

          const SizedBox(height: 16),

          _buildFeatureRow(
            icon: Icons.people,
            title: 'dashboard_feature_artists_title'.tr(),
            description: 'dashboard_feature_artists_desc'.tr(),
          ),

          const SizedBox(height: 16),

          _buildFeatureRow(
            icon: Icons.camera_alt,
            title: 'dashboard_feature_capture_title'.tr(),
            description: 'dashboard_feature_capture_desc'.tr(),
          ),

          const SizedBox(height: 24),

          // CTA buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/auth/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtbeatColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'dashboard_explanation_get_started'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/auth/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArtbeatColors.primaryPurple,
                    side: const BorderSide(color: ArtbeatColors.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'dashboard_explanation_sign_in'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
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
                  color: ArtbeatColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
