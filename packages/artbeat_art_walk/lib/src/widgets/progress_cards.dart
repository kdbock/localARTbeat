import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/models.dart';
import 'package:easy_localization/easy_localization.dart';

/// Card widget for displaying in-progress art walks
class InProgressWalkCard extends StatelessWidget {
  final ArtWalkProgress progress;
  final VoidCallback onResume;
  final VoidCallback onPause;
  final VoidCallback onAbandon;
  final VoidCallback onTap;
  final String? walkTitle;

  const InProgressWalkCard({
    super.key,
    required this.progress,
    required this.onResume,
    required this.onPause,
    required this.onAbandon,
    required this.onTap,
    this.walkTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        progress.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(progress.status),
                          size: 16,
                          color: _getStatusColor(progress.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          progress.status.displayName,
                          style: TextStyle(
                            color: _getStatusColor(progress.status),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatLastActive(progress.lastActiveAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Walk title
              Text(
                walkTitle ?? 'Art Walk',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progress.visitedArt.length} of ${progress.totalArtCount} art pieces',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${(progress.progressPercentage * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.progressPercentage,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(progress.status),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.timer,
                    label: _formatDuration(progress.timeSpent),
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.stars,
                    label: '${progress.totalPointsEarned} pts',
                    context: context,
                  ),
                  if (progress.isStale) ...[
                    const SizedBox(width: 8),
                    _buildStatChip(
                      icon: Icons.warning,
                      label: 'Stale',
                      context: context,
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: progress.status == WalkStatus.paused
                          ? onResume
                          : onPause,
                      icon: Icon(
                        progress.status == WalkStatus.paused
                            ? Icons.play_arrow
                            : Icons.pause,
                      ),
                      label: Text(
                        progress.status == WalkStatus.paused
                            ? 'Resume'
                            : 'Pause',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getStatusColor(progress.status),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onAbandon,
                    icon: const Icon(Icons.delete_outline),
                    label: Text('art_walk_progress_cards_button_abandon'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required BuildContext context,
    Color? color,
  }) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(WalkStatus status) {
    switch (status) {
      case WalkStatus.inProgress:
        return Colors.green;
      case WalkStatus.paused:
        return Colors.orange;
      case WalkStatus.completed:
        return Colors.blue;
      case WalkStatus.abandoned:
        return Colors.red;
      case WalkStatus.notStarted:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(WalkStatus status) {
    switch (status) {
      case WalkStatus.inProgress:
        return Icons.play_circle;
      case WalkStatus.paused:
        return Icons.pause_circle;
      case WalkStatus.completed:
        return Icons.check_circle;
      case WalkStatus.abandoned:
        return Icons.cancel;
      case WalkStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return intl.DateFormat('MMM d').format(lastActive);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

/// Card widget for displaying completed art walks
class CompletedWalkCard extends StatelessWidget {
  final ArtWalkProgress progress;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onReview;
  final String? walkTitle;

  const CompletedWalkCard({
    super.key,
    required this.progress,
    required this.onTap,
    required this.onShare,
    required this.onReview,
    this.walkTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with completion badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    intl.DateFormat(
                      'MMM d, yyyy',
                    ).format(progress.completedAt!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Walk title
              Text(
                walkTitle ?? 'Art Walk',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // Completion stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.palette,
                    label: '${progress.visitedArt.length} pieces',
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.timer,
                    label: _formatDuration(progress.timeSpent),
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.stars,
                    label: '${progress.totalPointsEarned} pts',
                    context: context,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Perfect completion indicator
              if (progress.progressPercentage >= 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Perfect Walk - All art pieces visited!',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share),
                      label: Text('art_walk_progress_cards_button_share'.tr()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.rate_review),
                      label: Text('art_walk_progress_cards_button_review'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

/// Card widget for displaying user-created art walks
class CreatedWalkCard extends StatelessWidget {
  final ArtWalkModel walk;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const CreatedWalkCard({
    super.key,
    required this.walk,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with visibility status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: walk.isPublic
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          walk.isPublic ? Icons.public : Icons.lock,
                          size: 16,
                          color: walk.isPublic ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          walk.isPublic ? 'Public' : 'Private',
                          style: TextStyle(
                            color: walk.isPublic ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'share':
                          onShare();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text('art_walk_progress_cards_text_edit'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            const Icon(Icons.share),
                            const SizedBox(width: 8),
                            Text('art_walk_progress_cards_button_share'.tr()),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Walk title and description
              Text(
                walk.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              if (walk.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  walk.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.palette,
                    label: '${walk.artworkIds.length} pieces',
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.people,
                    label: '${walk.viewCount} views',
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<double>(
                    future: getAverageRating(walk.id),
                    builder: (context, snapshot) {
                      return _buildStatChip(
                        icon: Icons.star,
                        label:
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : '${snapshot.data?.toStringAsFixed(1) ?? '0.0'}',
                        context: context,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Creation date
              Text(
                'Created ${intl.DateFormat('MMM d, yyyy').format(walk.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying saved art walks
class SavedWalkCard extends StatelessWidget {
  final ArtWalkModel walk;
  final VoidCallback onTap;
  final VoidCallback onUnsave;
  final VoidCallback onStart;

  const SavedWalkCard({
    super.key,
    required this.walk,
    required this.onTap,
    required this.onUnsave,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with bookmark icon
              Row(
                children: [
                  const Icon(Icons.bookmark, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Saved Walk',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onUnsave,
                    icon: const Icon(Icons.bookmark_remove),
                    tooltip: 'Remove from saved',
                  ),
                ],
              ),

              // Walk title and description
              Text(
                walk.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              if (walk.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  walk.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.palette,
                    label: '${walk.artworkIds.length} pieces',
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<double>(
                    future: getAverageRating(walk.id),
                    builder: (context, snapshot) {
                      return _buildStatChip(
                        icon: Icons.star,
                        label:
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Loading...'
                            : '${snapshot.data?.toStringAsFixed(1) ?? '0.0'}',
                        context: context,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.access_time,
                    label: '${walk.estimatedDuration?.round() ?? 30}min',
                    context: context,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: Text('art_walk_progress_cards_button_start_walk'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Top-level function to get average rating for a walk
Future<double> getAverageRating(String walkId) async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('walk_reviews')
        .where('walkId', isEqualTo: walkId)
        .get();

    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('rating') && data['rating'] is num) {
        totalRating += (data['rating'] as num).toDouble();
        count++;
      }
    }

    return count > 0 ? totalRating / count : 0.0;
  } catch (e) {
    AppLogger.error('Error getting average rating: $e');
    return 0.0;
  }
}
