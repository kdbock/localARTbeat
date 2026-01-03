import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/shared_widgets.dart';

import 'avatar_widget.dart';
import '../models/comment_model.dart';

class FeedbackThreadWidget extends StatelessWidget {
  final List<CommentModel> comments;
  final void Function(CommentModel) onReply;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const FeedbackThreadWidget({
    super.key,
    required this.comments,
    required this.onReply,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final typeLabel = _localizedCommentType(comment.type);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarWidget(
                        avatarUrl: comment.userAvatarUrl,
                        userId: comment.userId,
                        displayName: comment.userName,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userName,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: const Color(0xFFE6FFFFFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeago.format(comment.createdAt.toDate()),
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xB3FFFFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      comment.content,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xC0FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Row(
                      children: [
                        HudButton(
                          onPressed: () => onReply(comment),
                          text: 'reply'.tr(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            typeLabel,
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF22D3EE),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _localizedCommentType(String type) {
    final normalized = type
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (normalized.isEmpty) {
      return type;
    }
    final key = 'comments_type_$normalized';
    final localized = key.tr();
    return localized == key ? type : localized;
  }
}
