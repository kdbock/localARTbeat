import 'package:flutter/material.dart';
import 'package:artbeat_core/src/theme/artbeat_typography.dart';

class ArtworkThemeWrapper extends StatelessWidget {
  final Widget child;

  const ArtworkThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        // Artwork grid and list view styles
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        // Artwork detail view styles
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: theme.colorScheme.surface,
          margin: EdgeInsets.zero,
        ),
        // Filter chip styles for artwork categories
        chipTheme: ChipThemeData(
          backgroundColor: theme.colorScheme.primary.withAlpha(25),
          labelStyle: ArtbeatTypography.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        // Artwork metadata styles
        dividerTheme: DividerThemeData(
          color: theme.colorScheme.outline.withAlpha(
            51,
          ), // 0.2 opacity = 51 in alpha
          space: 32,
          thickness: 1,
        ),
      ),
      child: child,
    );
  }
}
