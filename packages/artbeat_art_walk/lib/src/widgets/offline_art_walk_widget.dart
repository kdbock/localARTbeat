import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/glass_secondary_button.dart';
import 'package:artbeat_art_walk/src/widgets/gradient_cta_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:artbeat_art_walk/src/widgets/world_background.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OfflineArtWalkWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineArtWalkWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            borderRadius: 32,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _OfflineBadge(),
                const SizedBox(height: 24),
                Text(
                  'art_walk_offline_art_walk_widget_title'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle(),
                ),
                const SizedBox(height: 16),
                Text(
                  'art_walk_offline_art_walk_widget_description'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    const Color(0xFFFFFFFF).withValues(
                      red: 255.0,
                      green: 255.0,
                      blue: 255.0,
                      alpha: (0.78 * 255),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GradientCTAButton(
                  label: 'art_walk_button_try_again'.tr(),
                  icon: Icons.refresh,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 16),
                GlassSecondaryButton(
                  label:
                      'art_walk_offline_art_walk_widget_text_view_art_walks_list'
                          .tr(),
                  icon: Icons.map_outlined,
                  onTap: () {
                    Navigator.pushNamed(context, '/art-walk/list');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      width: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
              ),
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 40),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(
                  red: ((Colors.redAccent.r * 255.0).round().clamp(
                    0,
                    255,
                  )).toDouble(),
                  green: ((Colors.redAccent.g * 255.0).round().clamp(
                    0,
                    255,
                  )).toDouble(),
                  blue: ((Colors.redAccent.b * 255.0).round().clamp(
                    0,
                    255,
                  )).toDouble(),
                  alpha: (0.9 * 255),
                ),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.signal_wifi_off,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
