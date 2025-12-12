import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/capture_service.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

/// Widget for displaying a single comment
class CommentItemWidget extends StatefulWidget {
  final Map<String, dynamic> comment;
  final String captureId;
  final String currentUserId;
  final VoidCallback? onDeleted;

  const CommentItemWidget({
    Key? key,
    required this.comment,
    required this.captureId,
    required this.currentUserId,
    this.onDeleted,
  }) : super(key: key);

  @override
  State<CommentItemWidget> createState() => _CommentItemWidgetState();
}

class _CommentItemWidgetState extends State<CommentItemWidget> {
  late bool _isLiked;
  late int _likeCount;
  bool _isDeleting = false;
  final _captureService = CaptureService();

  @override
  void initState() {
    super.initState();
    _likeCount = (widget.comment['likeCount'] as int?) ?? 0;
    _isLiked =
        (widget.comment['likedBy'] as List?)?.contains(widget.currentUserId) ??
        false;
  }

  Future<void> _deleteComment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('capture_comment_delete_title'.tr()),
        content: Text('capture_comment_delete_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('capture_comment_delete_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('capture_comment_delete_confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final success = await _captureService.deleteComment(
        widget.captureId,
        widget.comment['id'] as String,
      );

      if (success) {
        widget.onDeleted?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('capture_comment_deleted_success'.tr())),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_comment_error_generic'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _toggleCommentLike() async {
    try {
      final commentId = widget.comment['id'] as String;

      if (_isLiked) {
        await _captureService.unlikeComment(commentId, widget.currentUserId);
      } else {
        await _captureService.likeComment(commentId, widget.currentUserId);
      }

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      AppLogger.error('Error toggling comment like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_comment_error_generic'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.comment['userId'] as String?;
    final userName = widget.comment['userName'] as String? ?? 'Anonymous';
    final userAvatar = widget.comment['userAvatar'] as String?;
    final text = widget.comment['text'] as String? ?? '';
    final createdAt = widget.comment['createdAt'] as dynamic;

    DateTime? commentDate;
    if (createdAt is Timestamp) {
      commentDate = createdAt.toDate();
    }

    final isOwner = userId == widget.currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                ? NetworkImage(userAvatar)
                : null,
            child: userAvatar == null || userAvatar.isEmpty
                ? const Icon(Icons.person, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      commentDate != null ? _formatDate(commentDate) : '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(text, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                // Like and delete buttons
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: _toggleCommentLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _isLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _likeCount > 0 ? _likeCount.toString() : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isLiked ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Delete button (only for owner)
                    if (isOwner)
                      GestureDetector(
                        onTap: _isDeleting ? null : _deleteComment,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isDeleting)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                            const SizedBox(width: 4),
                            const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
