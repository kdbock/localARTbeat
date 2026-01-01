import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';

/// Dialog for reporting posts with predefined reasons
class ReportDialog extends StatefulWidget {
  final String postId;
  final String postContent;
  final void Function(String reason, String? details) onReport;

  const ReportDialog({
    super.key,
    required this.postId,
    required this.postContent,
    required this.onReport,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();

  final List<Map<String, String>> _reportReasons = [
    {
      'value': 'spam',
      'label': 'Spam or misleading',
      'label_key': 'report_reason_spam_label',
      'description':
          'Unsolicited commercial content, scams, or intentionally deceptive material',
      'description_key': 'report_reason_spam_description',
    },
    {
      'value': 'harassment',
      'label': 'Harassment or bullying',
      'label_key': 'report_reason_harassment_label',
      'description':
          'Threatening, abusive, or harassing behavior towards others',
      'description_key': 'report_reason_harassment_description',
    },
    {
      'value': 'inappropriate',
      'label': 'Inappropriate content',
      'label_key': 'report_reason_inappropriate_label',
      'description':
          'Nudity, sexual content, violence, or other inappropriate material',
      'description_key': 'report_reason_inappropriate_description',
    },
    {
      'value': 'hate_speech',
      'label': 'Hate speech',
      'label_key': 'report_reason_hate_speech_label',
      'description':
          'Content that promotes discrimination or violence against groups',
      'description_key': 'report_reason_hate_speech_description',
    },
    {
      'value': 'copyright',
      'label': 'Copyright violation',
      'label_key': 'report_reason_copyright_label',
      'description': 'Content that infringes on intellectual property rights',
      'description_key': 'report_reason_copyright_description',
    },
    {
      'value': 'other',
      'label': 'Other',
      'label_key': 'report_reason_other_label',
      'description': 'Something else not covered by the options above',
      'description_key': 'report_reason_other_description',
    },
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: GlassCard(
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'report_dialog_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Post preview
            GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'report_dialog_post_content_label'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 179),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.postContent.isNotEmpty
                        ? widget.postContent.length > 100
                              ? '${widget.postContent.substring(0, 100)}...'
                              : widget.postContent
                        : 'report_dialog_no_text_content'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report reasons
            Text(
              'report_dialog_reason_question'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _reportReasons.length,
                itemBuilder: (context, index) {
                  final reason = _reportReasons[index];
                  final isSelected = _selectedReason == reason['value'];

                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    glassOpacity: isSelected ? 0.12 : 0.08,
                    borderOpacity: isSelected ? 0.2 : 0.12,
                    showAccentGlow: isSelected,
                    accentColor: const Color(0xFF22D3EE),
                    child: RadioListTile<String>(
                      title: Text(
                        reason['label_key']!.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        reason['description_key']!.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 179),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: reason['value']!,
                      // ignore: deprecated_member_use
                      groupValue: _selectedReason,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          _selectedReason = value;
                        });
                      },
                      activeColor: const Color(0xFF22D3EE),
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ),

            // Additional details
            if (_selectedReason != null) ...[
              const SizedBox(height: 24),
              Text(
                'report_dialog_additional_details_label'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: GlassInputDecoration(
                  hintText: 'report_dialog_details_hint'.tr(),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(
                    'cancel'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 179),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                HudButton.primary(
                  onPressed: _selectedReason != null ? _submitReport : null,
                  text: 'report_dialog_submit_button'.tr(),
                  width: 140,
                  height: 44,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport() {
    if (_selectedReason == null) return;

    final reason = _reportReasons.firstWhere(
      (r) => r['value'] == _selectedReason,
    )['label']!;

    final details = _detailsController.text.trim().isNotEmpty
        ? _detailsController.text.trim()
        : null;

    widget.onReport(reason, details);
    Navigator.of(context).pop();
  }
}
