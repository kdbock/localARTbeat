import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ArtCaptureWarningDialog extends StatelessWidget {
  const ArtCaptureWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('art_capture_warning_title'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'art_capture_warning_intro'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('art_capture_warning_rule_public_spaces'.tr()),
            Text('art_capture_warning_rule_private_property'.tr()),
            Text('art_capture_warning_rule_no_photography'.tr()),
            Text('art_capture_warning_rule_commissioned_works'.tr()),
            Text('art_capture_warning_rule_credit_artists'.tr()),
            const SizedBox(height: 16),
            Text(
              'art_capture_warning_confirmation'.tr(),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('common_cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('permission_i_understand'.tr()),
        ),
      ],
    );
  }
}
