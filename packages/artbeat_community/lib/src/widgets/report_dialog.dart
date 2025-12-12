import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/moderation_service.dart';

/// Dialog for reporting content or users
class ReportDialog extends StatefulWidget {
  final String reportedUserId;
  final String contentId;
  final String contentType;
  final String? reportingUserId;
  final VoidCallback? onReportSubmitted;

  const ReportDialog({
    super.key,
    required this.reportedUserId,
    required this.contentId,
    required this.contentType,
    this.reportingUserId,
    this.onReportSubmitted,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _descriptionController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('art_walk_report_dialog_select_reason'.tr())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await _moderationService.reportContent(
        reportedUserId: widget.reportedUserId,
        contentId: widget.contentId,
        contentType: widget.contentType,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        reportingUserId: widget.reportingUserId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('art_walk_report_dialog_submitted'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          widget.onReportSubmitted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('art_walk_report_dialog_failed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_report_dialog_error'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('art_walk_report_dialog_title'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'art_walk_report_dialog_description'.tr(),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButton<ReportReason>(
              isExpanded: true,
              value: _selectedReason,
              hint: Text('art_walk_report_dialog_select_reason_hint'.tr()),
              items: ReportReason.values.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason.displayName),
                );
              }).toList(),
              onChanged: (ReportReason? value) {
                setState(() => _selectedReason = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'art_walk_report_dialog_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text('art_walk_report_dialog_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('art_walk_report_dialog_report'.tr()),
        ),
      ],
    );
  }
}
