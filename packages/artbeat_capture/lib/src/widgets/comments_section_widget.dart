import 'package:flutter/material.dart';
import '../services/capture_service.dart';
import 'comment_item_widget.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

/// Widget for displaying and managing comments on a capture
class CommentsSectionWidget extends StatefulWidget {
  final String captureId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final VoidCallback? onCommentAdded;

  const CommentsSectionWidget({
    Key? key,
    required this.captureId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentsSectionWidget> createState() => _CommentsSectionWidgetState();
}

class _CommentsSectionWidgetState extends State<CommentsSectionWidget> {
  final _captureService = CaptureService();
  final _commentController = TextEditingController();
  late Future<List<dynamic>> _commentsFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    _commentsFuture = _captureService.getComments(widget.captureId);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final commentId = await _captureService.addComment(
        captureId: widget.captureId,
        userId: widget.userId,
        userName: widget.userName,
        userAvatar: widget.userAvatar ?? '',
        text: text,
      );

      if (commentId != null) {
        _commentController.clear();
        _loadComments();
        widget.onCommentAdded?.call();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('capture_comments_added_success'.tr())));
        }
      }
    } catch (e) {
      AppLogger.error('Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('capture_comments_error_generic'.tr().replaceAll('{error}', e.toString()))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'capture_comments_section_title'.tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        // Comments list
        FutureBuilder<List<dynamic>>(
          future: _commentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('capture_comments_error_loading'.tr().replaceAll('{error}', snapshot.error.toString())),
              );
            }

            final comments = snapshot.data ?? [];

            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('capture_comments_no_comments'.tr()),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return CommentItemWidget(
                  comment: comments[index] as Map<String, dynamic>,
                  captureId: widget.captureId,
                  currentUserId: widget.userId,
                  onDeleted: () {
                    _loadComments();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              },
            );
          },
        ),

        // Comment input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    widget.userAvatar != null && widget.userAvatar!.isNotEmpty
                    ? NetworkImage(widget.userAvatar!)
                    : null,
                child: widget.userAvatar == null || widget.userAvatar!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              // Input field and submit button
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              // Submit button
              GestureDetector(
                onTap: _isSubmitting ? null : _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
