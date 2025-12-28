import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OfflineMapFallback extends StatelessWidget {
  static const String _legacyDefaultError = 'Unable to load map';

  final VoidCallback onRetry;
  final bool hasData;
  final String errorMessage;
  final List<PublicArtModel> nearbyArt;

  const OfflineMapFallback({
    super.key,
    required this.onRetry,
    this.hasData = false,
    this.errorMessage = _legacyDefaultError,
    this.nearbyArt = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cachedCount = hasData ? nearbyArt.length : 0;
    final hasCachedArt = hasData && cachedCount > 0;
    final titleKey = hasCachedArt
        ? 'art_walk_offline_map_fallback_title_offline'
        : 'art_walk_offline_map_fallback_title_error';
    final helperKey = hasCachedArt
        ? 'art_walk_offline_map_fallback_helper_offline'
        : 'art_walk_offline_map_fallback_helper_error';
    final statusChipLabel = hasCachedArt
        ? 'art_walk_offline_map_fallback_chip_cached_art'.tr(
            namedArgs: {'count': cachedCount.toString()},
          )
        : 'art_walk_offline_map_fallback_chip_empty'.tr();
    final statusIcon = hasCachedArt ? Icons.offline_pin : Icons.cloud_off;
    final description = hasCachedArt
        ? 'art_walk_offline_map_fallback_description_offline'.tr(
            namedArgs: {'count': cachedCount.toString()},
          )
        : _resolveErrorDescription();

    return WorldBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            borderRadius: 32,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _OfflineMapBadge(hasCachedArt: hasCachedArt),
                  const SizedBox(height: 24),
                  Text(
                    titleKey.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.screenTitle(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusChip(label: statusChipLabel, icon: statusIcon),
                  const SizedBox(height: 24),
                  GradientCTAButton(
                    label: 'art_walk_button_try_again'.tr(),
                    icon: Icons.refresh,
                    onPressed: onRetry,
                  ),
                  if (hasCachedArt) ...[
                    const SizedBox(height: 16),
                    GlassSecondaryButton(
                      label:
                          'art_walk_offline_map_fallback_text_view_art_walk_list'
                              .tr(),
                      icon: Icons.list_alt,
                      onTap: () {
                        Navigator.pushNamed(context, '/art-walk/list');
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    helperKey.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.helper(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resolveErrorDescription() {
    final trimmed = errorMessage.trim();
    if (trimmed.isNotEmpty && trimmed != _legacyDefaultError) {
      return trimmed;
    }
    return 'art_walk_offline_map_fallback_description_error'.tr();
  }
}

class _OfflineMapBadge extends StatelessWidget {
  final bool hasCachedArt;

  const _OfflineMapBadge({required this.hasCachedArt});

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
              boxShadow: [
                BoxShadow(
                  color: Color(0x5522D3EE),
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: const Icon(
              Icons.map_outlined,
              color: Colors.white,
              size: 42,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasCachedArt
                    ? const Color(0xFF34D399)
                    : Colors.redAccent.withValues(alpha: 0.9),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                hasCachedArt ? Icons.offline_pin : Icons.signal_wifi_off,
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

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.badge()),
        ],
      ),
    );
  }
}
