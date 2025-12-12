import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

/// Read-only screen for viewing existing capture details
class CaptureViewScreen extends StatelessWidget {
  final core.CaptureModel capture;

  const CaptureViewScreen({Key? key, required this.capture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          capture.title ?? 'capture_detail_viewer_default_title'.tr(),
        ),
        backgroundColor: core.ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (capture.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: core.OptimizedImage(
                  imageUrl: capture.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text(
              capture.title ?? 'capture_detail_viewer_untitled'.tr(),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            // Artist
            if (capture.artistName != null) ...[
              const SizedBox(height: 8),
              Text(
                'capture_detail_viewer_by_artist'.tr().replaceAll(
                  '{artist}',
                  capture.artistName!,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],

            // Art Type
            if (capture.artType != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.palette,
                'Art Type',
                capture.artType!,
              ),
            ],

            // Art Medium
            if (capture.artMedium != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.brush, 'Medium', capture.artMedium!),
            ],

            // Location
            if (capture.locationName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.location_on,
                'Location',
                capture.locationName!,
              ),
            ],

            // Description
            if (capture.description != null &&
                capture.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'capture_detail_viewer_description'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                capture.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            // Created date
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Captured',
              _formatDate(capture.createdAt),
            ),

            // Privacy status
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              capture.isPublic ? Icons.public : Icons.lock,
              'Visibility',
              capture.isPublic ? 'Public' : 'Private',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}
