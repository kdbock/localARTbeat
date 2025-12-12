import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/ad_report_model.dart';

/// Dialog for reporting ads with predefined reasons
class AdReportDialog extends StatefulWidget {
  final String adId;
  final String adTitle;
  final String adDescription;
  final void Function(String reason, String? details) onReport;

  const AdReportDialog({
    super.key,
    required this.adId,
    required this.adTitle,
    required this.adDescription,
    required this.onReport,
  });

  @override
  State<AdReportDialog> createState() => _AdReportDialogState();
}

class _AdReportDialogState extends State<AdReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArtbeatColors.backgroundDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x19FF0000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flag, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ads_ad_report_text_report_advertisement'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ad Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ads_ad_report_text_ad_prefix'.tr() + widget.adTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.adDescription.length > 100
                        ? '${widget.adDescription.substring(0, 100)}...'
                        : widget.adDescription,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report Reason
            Text(
              'ads_ad_report_text_whats_wrong'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Reason Options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: AdReportReasons.reasons.map((reason) {
                    final isSelected = _selectedReason == reason['value'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? ArtbeatColors.primary
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? ArtbeatColors.primary
                                  : Colors.grey.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            color: isSelected
                                ? ArtbeatColors.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        title: Text(
                          reason['label']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          reason['description']!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedReason = reason['value'];
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional Details (Optional)
            TextField(
              controller: _detailsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Additional details (optional)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText:
                    'Provide more context about why you\'re reporting this ad...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ArtbeatColors.primary),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ads_ad_report_text_cancel'.tr(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedReason == null
                        ? null
                        : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ads_ad_report_text_submit_report'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Disclaimer
            Text(
              'ads_ad_report_text_disclaimer'.tr(),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport() async {
    if (_selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      ); // Brief delay for UX

      widget.onReport(
        _selectedReason!,
        _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'ads_ad_report_text_failed_to_submit'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

/// Simple report button widget that can be added to ad displays
class AdReportButton extends StatelessWidget {
  final String adId;
  final String adTitle;
  final String adDescription;
  final Future<bool> Function(String adId, String reason, String? details)
  onReport;
  final bool showText;

  const AdReportButton({
    super.key,
    required this.adId,
    required this.adTitle,
    required this.adDescription,
    required this.onReport,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return showText
        ? TextButton.icon(
            onPressed: () => _showReportDialog(context),
            icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
            label: Text(
              'ads_ad_report_text_report'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        : IconButton(
            onPressed: () => _showReportDialog(context),
            icon: const Icon(Icons.flag_outlined, color: Colors.grey, size: 20),
            tooltip: 'Report this ad',
          );
  }

  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AdReportDialog(
        adId: adId,
        adTitle: adTitle,
        adDescription: adDescription,
        onReport: (reason, details) async {
          try {
            final success = await onReport(adId, reason, details);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ads_ad_report_text_report_submitted'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${'ads_ad_report_text_failed_to_submit'.tr()}: $e',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
