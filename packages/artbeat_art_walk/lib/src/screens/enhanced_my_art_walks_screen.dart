import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../constants/routes.dart';

/// Helper class for empty state configuration
class _EmptyStateConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  _EmptyStateConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });
}

/// Enhanced screen for managing user's art walks with progress tracking
class EnhancedMyArtWalksScreen extends StatefulWidget {
  const EnhancedMyArtWalksScreen({super.key});

  @override
  State<EnhancedMyArtWalksScreen> createState() =>
      _EnhancedMyArtWalksScreenState();
}

class _EnhancedMyArtWalksScreenState extends State<EnhancedMyArtWalksScreen> {
  final ArtWalkService _artWalkService = ArtWalkService();
  final ArtWalkProgressService _progressService = ArtWalkProgressService();

  String? _userId;
  bool _isLoading = true;

  // Data for each tab
  List<ArtWalkProgress> _inProgressWalks = [];
  List<ArtWalkProgress> _completedWalks = [];
  List<ArtWalkModel> _createdWalks = [];
  List<ArtWalkModel> _savedWalks = [];

  // Cache for walk titles
  final Map<String, String> _walkTitles = {};

  @override
  void initState() {
    super.initState();
    _userId = _artWalkService.getCurrentUserId();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Load data for all tabs concurrently
      final results = await Future.wait([
        _progressService.getIncompleteWalks(_userId!),
        _progressService.getCompletedWalks(_userId!),
        _artWalkService.getUserCreatedWalks(_userId!),
        _artWalkService.getUserSavedWalks(_userId!),
      ]);

      if (mounted) {
        setState(() {
          _inProgressWalks = results[0] as List<ArtWalkProgress>;
          _completedWalks = results[1] as List<ArtWalkProgress>;
          _createdWalks = results[2] as List<ArtWalkModel>;
          _savedWalks = results[3] as List<ArtWalkModel>;
          _isLoading = false;
        });

        // Fetch walk titles for progress cards
        _fetchWalkTitles();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_my_art_walks_error_error_loading_data'.tr(),
            ),
          ),
        );
      }
    }
  }

  /// Fetch walk titles for all progress items
  Future<void> _fetchWalkTitles() async {
    // Collect all unique walk IDs
    final walkIds = <String>{
      ..._inProgressWalks.map((p) => p.artWalkId),
      ..._completedWalks.map((p) => p.artWalkId),
    };

    // Fetch titles for walks we don't have yet
    for (final walkId in walkIds) {
      if (!_walkTitles.containsKey(walkId)) {
        try {
          final walk = await _artWalkService.getArtWalkById(walkId);
          if (walk != null && mounted) {
            setState(() {
              _walkTitles[walkId] = walk.title;
            });
          }
        } catch (e) {
          // Silently fail - will use default title
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return _buildNotLoggedInView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('art_walk_enhanced_my_art_walks_text_my_art_walks'.tr()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSingleScrollView(),
    );
  }

  Widget _buildSingleScrollView() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In Progress Section
                _buildSection(
                  title: 'In Progress',
                  icon: Icons.play_circle_outline,
                  count: _inProgressWalks.length,
                  isEmpty: _inProgressWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.explore,
                    title: 'No walks in progress',
                    subtitle:
                        'Start exploring art walks to see your progress here',
                    actionText: 'Explore Walks',
                    onAction: () =>
                        Navigator.pushNamed(context, ArtWalkRoutes.dashboard),
                  ),
                  builder: () => Column(
                    children: _inProgressWalks
                        .map(
                          (progress) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InProgressWalkCard(
                              progress: progress,
                              walkTitle: _walkTitles[progress.artWalkId],
                              onResume: () => _resumeWalk(progress),
                              onPause: () => _pauseWalk(progress),
                              onAbandon: () => _abandonWalk(progress),
                              onTap: () => _viewWalkDetails(progress.artWalkId),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Completed Section
                _buildSection(
                  title: 'Completed',
                  icon: Icons.check_circle_outline,
                  count: _completedWalks.length,
                  isEmpty: _completedWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.check_circle,
                    title: 'No completed walks yet',
                    subtitle: 'Complete your first art walk to see it here',
                    actionText: 'Start Walking',
                    onAction: () =>
                        Navigator.pushNamed(context, ArtWalkRoutes.dashboard),
                  ),
                  builder: () => Column(
                    children: _completedWalks
                        .map(
                          (progress) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CompletedWalkCard(
                              progress: progress,
                              walkTitle: _walkTitles[progress.artWalkId],
                              onTap: () => _viewWalkDetails(progress.artWalkId),
                              onShare: () => _shareWalkCompletion(progress),
                              onReview: () => _reviewWalk(progress),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Created Section
                _buildSection(
                  title: 'Created',
                  icon: Icons.create_outlined,
                  count: _createdWalks.length,
                  isEmpty: _createdWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.create,
                    title: 'No walks created yet',
                    subtitle:
                        'Share your favorite art spots by creating a walk',
                    actionText: 'Create Walk',
                    onAction: () => Navigator.pushNamed(
                      context,
                      ArtWalkRoutes.enhancedCreate,
                    ),
                  ),
                  builder: () => Column(
                    children: _createdWalks
                        .map(
                          (walk) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CreatedWalkCard(
                              walk: walk,
                              onTap: () => _viewWalkDetails(walk.id),
                              onEdit: () => _editWalk(walk),
                              onDelete: () => _deleteWalk(walk),
                              onShare: () => _shareWalk(walk),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Saved Section
                _buildSection(
                  title: 'Saved',
                  icon: Icons.bookmark_outline,
                  count: _savedWalks.length,
                  isEmpty: _savedWalks.isEmpty,
                  emptyStateConfig: _EmptyStateConfig(
                    icon: Icons.bookmark,
                    title: 'No saved walks yet',
                    subtitle:
                        'Save interesting walks to find them easily later',
                    actionText: 'Browse Walks',
                    onAction: () =>
                        Navigator.pushNamed(context, ArtWalkRoutes.dashboard),
                  ),
                  builder: () => Column(
                    children: _savedWalks
                        .map(
                          (walk) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SavedWalkCard(
                              walk: walk,
                              onTap: () => _viewWalkDetails(walk.id),
                              onUnsave: () => _unsaveWalk(walk),
                              onStart: () => _startWalk(walk),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () =>
                Navigator.pushNamed(context, ArtWalkRoutes.enhancedCreate),
            icon: const Icon(Icons.add),
            label: Text('art_walk_create'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required int count,
    required bool isEmpty,
    required _EmptyStateConfig emptyStateConfig,
    required Widget Function() builder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Content or Empty State
        isEmpty ? _buildCompactEmptyState(emptyStateConfig) : builder(),
      ],
    );
  }

  Widget _buildCompactEmptyState(_EmptyStateConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            config.icon,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  config.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: config.onAction,
            child: Text(config.actionText),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('art_walk_enhanced_my_art_walks_text_my_art_walks'.tr()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your art walks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('art_walk_enhanced_my_art_walks_text_log_in'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _resumeWalk(ArtWalkProgress progress) async {
    try {
      await _progressService.resumeWalk(progress.id);
      Navigator.pushNamed(
        // ignore: use_build_context_synchronously
        context,
        '/art-walk-experience',
        arguments: {'artWalkId': progress.artWalkId},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_error_error_resuming_walk'
                .tr(),
          ),
        ),
      );
    }
  }

  Future<void> _pauseWalk(ArtWalkProgress progress) async {
    try {
      await _progressService.pauseWalk();
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_art_walk_experience_error_error_pausing_walk'
                .tr(),
          ),
        ),
      );
    }
  }

  Future<void> _abandonWalk(ArtWalkProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'art_walk_enhanced_art_walk_experience_text_abandon_walk_76'.tr(),
        ),
        content: const Text(
          'Are you sure you want to abandon this walk? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'art_walk_enhanced_art_walk_experience_text_abandon'.tr(),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _progressService.abandonWalk();
        _loadAllData();
      } catch (e) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_art_walk_experience_error_error_abandoning_walk'
                  .tr(),
            ),
          ),
        );
      }
    }
  }

  void _viewWalkDetails(String walkId) {
    Navigator.pushNamed(
      context,
      '/art-walk-detail',
      arguments: {'walkId': walkId},
    );
  }

  void _shareWalkCompletion(ArtWalkProgress progress) {
    // Implement sharing logic
  }

  void _reviewWalk(ArtWalkProgress progress) {
    showDialog<void>(
      context: context,
      builder: (context) => WalkReviewDialog(
        progress: progress,
        walkTitle: _walkTitles[progress.artWalkId],
        onSubmitReview: (double rating, String review) async {
          try {
            // Save rating and review to Firestore
            await FirebaseFirestore.instance.collection('walk_reviews').add({
              'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
              'artWalkId': progress.artWalkId,
              'rating': rating,
              'review': review,
              'createdAt': FieldValue.serverTimestamp(),
              'progressId': progress.id,
            });

            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Thank you for your ${rating.toInt()}-star review!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'art_walk_enhanced_my_art_walks_error_failed_to_save'.tr(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _editWalk(ArtWalkModel walk) {
    Navigator.pushNamed(
      context,
      '/edit-art-walk',
      arguments: {'walkId': walk.id},
    );
  }

  Future<void> _deleteWalk(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('art_walk_enhanced_my_art_walks_text_delete_walk'.tr()),
        content: Text(
          'Are you sure you want to delete "${walk.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'admin_modern_unified_admin_dashboard_text_delete'.tr(),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _artWalkService.deleteArtWalk(walk.id);
        _loadAllData();
      } catch (e) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_my_art_walks_error_error_deleting_walk'.tr(),
            ),
          ),
        );
      }
    }
  }

  void _shareWalk(ArtWalkModel walk) {
    // Implement sharing logic
  }

  Future<void> _unsaveWalk(ArtWalkModel walk) async {
    try {
      await _artWalkService.unsaveArtWalk(walk.id);
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_enhanced_my_art_walks_error_error_unsaving_walk'.tr(),
          ),
        ),
      );
    }
  }

  void _startWalk(ArtWalkModel walk) {
    Navigator.pushNamed(
      context,
      ArtWalkRoutes.experience,
      arguments: {'artWalkId': walk.id, 'artWalk': walk},
    );
  }
}

/// Dialog for reviewing completed art walks with star rating
class WalkReviewDialog extends StatefulWidget {
  final ArtWalkProgress progress;
  final String? walkTitle;
  final Future<void> Function(double rating, String review) onSubmitReview;

  const WalkReviewDialog({
    super.key,
    required this.progress,
    this.walkTitle,
    required this.onSubmitReview,
  });

  @override
  State<WalkReviewDialog> createState() => _WalkReviewDialogState();
}

class _WalkReviewDialogState extends State<WalkReviewDialog> {
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.walkTitle ?? 'Art Walk'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating stars
            const Text(
              'How would you rate this art walk?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1.0),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            Text(
              _rating > 0
                  ? '${_rating.toInt()} star${_rating > 1 ? 's' : ''}'
                  : 'Tap stars to rate',
              style: TextStyle(
                color: _rating > 0 ? Colors.amber.shade700 : Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Review text field
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Share your thoughts (optional)',
                hintText: 'What did you enjoy about this walk?',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),

            const SizedBox(height: 16),

            // Walk stats summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Walk Summary',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${widget.progress.visitedArt.length} art pieces visited',
                  ),
                  Text(
                    'art_walk_enhanced_my_art_walks_text_widgetprogresstotalpointsearned_points_earned'
                        .tr(),
                  ),
                  Text(
                    '• Completed in ${_formatDuration(widget.progress.timeSpent)}',
                  ),
                  if (widget.progress.progressPercentage >= 1.0)
                    Text(
                      'art_walk_enhanced_my_art_walks_text_perfect_walk_all'
                          .tr(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text('admin_admin_payment_text_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _rating == 0.0 ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('art_walk_enhanced_my_art_walks_text_submit_review'.tr()),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0.0) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmitReview(_rating, _reviewController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_enhanced_my_art_walks_error_error_submitting_review'
                  .tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
