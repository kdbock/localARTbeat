import 'package:flutter/material.dart';
import 'package:artbeat_core/src/theme/artbeat_typography.dart';

class ArtistThemeWrapper extends StatelessWidget {
  final Widget child;

  const ArtistThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        // Portfolio specific theme overrides
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          titleTextStyle: ArtbeatTypography.textTheme.titleMedium,
          subtitleTextStyle: ArtbeatTypography.textTheme.bodyMedium,
        ),
        // Artist badge and verification styles
        badgeTheme: BadgeThemeData(
          backgroundColor: theme.colorScheme.secondary,
          textColor: theme.colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          alignment: AlignmentDirectional.topEnd,
        ),
        // Stats and analytics card styles
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.colorScheme.surface,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      child: child,
    );
  }
}
