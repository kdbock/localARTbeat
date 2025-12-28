import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

class ArtProgressCard extends StatelessWidget {
  final int visited;
  final int total;

  const ArtProgressCard({
    super.key,
    required this.visited,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$visited / $total',
            style: AppTextStyles.cardTitleWhite.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'art_walk_art_pieces_visited'.tr(),
            style: AppTextStyles.cardCaptionWhite,
          ),
        ],
      ),
    );
  }
}
