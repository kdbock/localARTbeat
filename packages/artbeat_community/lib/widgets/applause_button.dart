import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_community/widgets/glass_card.dart';

class ApplauseButton extends StatelessWidget {
  final String postId;
  final String userId;
  final VoidCallback onTap;
  final int count;
  final int maxApplause;
  final Color? color;

  const ApplauseButton({
    super.key,
    required this.postId,
    required this.userId,
    required this.onTap,
    required this.count,
    this.maxApplause = 5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final applauseColor = color ?? ArtbeatColors.accentYellow;
    final isEnabled =
        count < maxApplause && postId.isNotEmpty && userId.isNotEmpty;

    // Safety check for required data
    if (postId.isEmpty) {
      AppLogger.warning('⚠️ ApplauseButton: postId is empty');
      return const GlassCard(
        padding: EdgeInsets.all(8),
        borderRadius: 16,
        glassOpacity: 0.04,
        borderOpacity: 0.08,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.front_hand, size: 18, color: Colors.grey),
            SizedBox(width: 8),
            Text('--', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      glassOpacity: isEnabled ? 0.08 : 0.04,
      borderOpacity: isEnabled ? 0.12 : 0.08,
      showAccentGlow: isEnabled,
      accentColor: applauseColor,
      child: InkWell(
        onTap: isEnabled
            ? () {
                debugPrint(
                  'ApplauseButton onTap called - postId: $postId, userId: $userId, enabled: $isEnabled',
                );
                onTap();
              }
            : () {
                debugPrint(
                  'ApplauseButton disabled - postId: $postId, userId: $userId, count: $count, maxApplause: $maxApplause',
                );
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.front_hand,
                size: 18,
                color: isEnabled
                    ? applauseColor
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: GoogleFonts.spaceGrotesk(
                  color: isEnabled
                      ? applauseColor
                      : Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
