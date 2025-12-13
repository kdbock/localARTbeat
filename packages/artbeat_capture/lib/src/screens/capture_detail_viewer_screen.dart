import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:share_plus/share_plus.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

/// Screen for viewing existing capture details with likes, comments, and interactions
class CaptureDetailViewerScreen extends StatefulWidget {
  final String captureId;

  const CaptureDetailViewerScreen({Key? key, required this.captureId})
    : super(key: key);

  @override
  State<CaptureDetailViewerScreen> createState() =>
      _CaptureDetailViewerScreenState();
}

class _CaptureDetailViewerScreenState extends State<CaptureDetailViewerScreen> {
  final CaptureService _captureService = CaptureService();
  core.CaptureModel? _capture;
  bool _isLoading = true;
  String? _error;

  bool _isOwner = false;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadCapture();
  }

  Future<void> _loadCapture() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final capture = await _captureService.getCaptureById(widget.captureId);

      if (capture == null) {
        setState(() {
          _error = 'Capture not found';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _capture = capture;
          _isOwner = capture.userId == _currentUserId;
          _isLoading = false;
        });
      }
    } catch (e) {
      core.AppLogger.error('Error loading capture: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load capture: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'capture_admin_content_moderation_text_delete_capture'.tr(),
        ),
        content: Text('capture_capture_detail_viewer_text_are_you_sure'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCapture();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'admin_modern_unified_admin_dashboard_text_delete'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCapture() async {
    try {
      await _captureService.deleteCapture(widget.captureId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_capture_detail_viewer_success_capture_deleted_successfully'
                  .tr(),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      core.AppLogger.error('Error deleting capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_capture_detail_viewer_error_failed_to_delete'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareCapture() {
    if (_capture == null) return;

    final title = _capture!.title ?? 'Art Capture';
    final text = _capture!.description ?? '';

    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this art capture on ArtBeat!\n\n$title\n$text',
        subject: title,
      ),
    );
  }

  void _editCapture() {
    Navigator.of(
      context,
    ).pushNamed('/capture/edit', arguments: {'capture': _capture});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _capture?.title ?? 'capture_detail_viewer_default_title'.tr(),
        ),
        backgroundColor: core.ArtbeatColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editCapture,
              tooltip: 'Edit capture',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete capture',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCapture,
                    child: Text('admin_admin_settings_text_retry'.tr()),
                  ),
                ],
              ),
            )
          : _capture == null
          ? Center(
              child: Text(
                'capture_capture_detail_viewer_text_no_capture_found'.tr(),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: core.OptimizedImage(
                      imageUrl: _capture!.imageUrl,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _capture!.title ?? 'capture_detail_viewer_untitled'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Artist
                  if (_capture!.artistName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'capture_detail_viewer_by_artist'.tr().replaceAll(
                        '{artist}',
                        _capture!.artistName!,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Info rows
                  if (_capture!.artType != null)
                    _buildInfoRow(
                      context,
                      Icons.palette,
                      'Art Type',
                      _capture!.artType!,
                    ),

                  if (_capture!.artMedium != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      Icons.brush,
                      'Medium',
                      _capture!.artMedium!,
                    ),
                  ],

                  if (_capture!.locationName != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      Icons.location_on,
                      'Location',
                      _capture!.locationName!,
                    ),
                  ],

                  // Description
                  if (_capture!.description != null &&
                      _capture!.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'capture_detail_viewer_description'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _capture!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],

                  // Status
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.info,
                    'Status',
                    _capture!.status.value,
                  ),

                  // Date
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    'Captured',
                    _formatDate(_capture!.createdAt),
                  ),

                  // Visibility
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    _capture!.isPublic ? Icons.public : Icons.lock,
                    'Visibility',
                    _capture!.isPublic ? 'Public' : 'Private',
                  ),

                  const SizedBox(height: 24),

                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Share button
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onPressed: _shareCapture,
                      ),
                      // Like button with count
                      LikeButtonWidget(
                        captureId: widget.captureId,
                        userId: _currentUserId,
                        initialLikeCount: _capture!.engagementStats.likeCount,
                        onLikeChanged: () {
                          // Refresh capture to update like count
                          _loadCapture();
                        },
                      ),
                      // Comment count
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.comment,
                            color: core.ArtbeatColors.primaryPurple,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _capture!.engagementStats.commentCount.toString(),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Comments section
                  CommentsSectionWidget(
                    captureId: widget.captureId,
                    userId: _currentUserId,
                    userName:
                        FirebaseAuth.instance.currentUser?.displayName ??
                        'Anonymous',
                    userAvatar: FirebaseAuth.instance.currentUser?.photoURL,
                    onCommentAdded: () {
                      // Refresh to update comment count
                      _loadCapture();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: core.ArtbeatColors.primaryPurple, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: core.ArtbeatColors.primaryPurple),
          onPressed: onPressed,
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
