import 'package:flutter/material.dart';
import '../models/artwork_model.dart';

/// Widget for displaying artwork moderation status
class ArtworkModerationStatusChip extends StatelessWidget {
  final ArtworkModerationStatus status;
  final bool showIcon;

  const ArtworkModerationStatusChip({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: showIcon ? _getStatusIcon() : null,
      label: Text(
        status.displayName,
        style: TextStyle(color: _getTextColor(), fontSize: 12),
      ),
      backgroundColor: _getBackgroundColor(),
      side: BorderSide(color: _getBorderColor(), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget? _getStatusIcon() {
    IconData? iconData;
    switch (status) {
      case ArtworkModerationStatus.pending:
        iconData = Icons.schedule;
        break;
      case ArtworkModerationStatus.approved:
        iconData = Icons.check_circle;
        break;
      case ArtworkModerationStatus.rejected:
        iconData = Icons.cancel;
        break;
      case ArtworkModerationStatus.flagged:
        iconData = Icons.flag;
        break;
      case ArtworkModerationStatus.underReview:
        iconData = Icons.visibility;
        break;
    }

    return Icon(iconData, size: 16, color: _getTextColor());
  }

  Color _getBackgroundColor() {
    switch (status) {
      case ArtworkModerationStatus.pending:
        return Colors.orange.withValues(alpha: 0.1);
      case ArtworkModerationStatus.approved:
        return Colors.green.withValues(alpha: 0.1);
      case ArtworkModerationStatus.rejected:
        return Colors.red.withValues(alpha: 0.1);
      case ArtworkModerationStatus.flagged:
        return Colors.orange.withValues(alpha: 0.1);
      case ArtworkModerationStatus.underReview:
        return Colors.blue.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case ArtworkModerationStatus.pending:
        return Colors.orange;
      case ArtworkModerationStatus.approved:
        return Colors.green;
      case ArtworkModerationStatus.rejected:
        return Colors.red;
      case ArtworkModerationStatus.flagged:
        return Colors.orange;
      case ArtworkModerationStatus.underReview:
        return Colors.blue;
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case ArtworkModerationStatus.pending:
        return Colors.orange.withValues(alpha: 0.3);
      case ArtworkModerationStatus.approved:
        return Colors.green.withValues(alpha: 0.3);
      case ArtworkModerationStatus.rejected:
        return Colors.red.withValues(alpha: 0.3);
      case ArtworkModerationStatus.flagged:
        return Colors.orange.withValues(alpha: 0.3);
      case ArtworkModerationStatus.underReview:
        return Colors.blue.withValues(alpha: 0.3);
    }
  }
}
