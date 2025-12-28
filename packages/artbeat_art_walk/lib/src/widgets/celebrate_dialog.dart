import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/gradient_cta_button.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

class CelebrateDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const CelebrateDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 28.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.cardTitleWhite.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientCTAButton(
              label: 'art_walk_awesome'.tr(),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
