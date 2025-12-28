import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

class SettingsModal extends StatelessWidget {
  final bool isSoundOn;
  final ValueChanged<bool> onSoundToggle;

  const SettingsModal({
    super.key,
    required this.isSoundOn,
    required this.onSoundToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 28.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'art_walk_settings'.tr(),
            style: AppTextStyles.cardTitleWhite.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('art_walk_sound'.tr(), style: AppTextStyles.bodyBold),
              Switch(value: isSoundOn, onChanged: onSoundToggle),
            ],
          ),
        ],
      ),
    );
  }
}
