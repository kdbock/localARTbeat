import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'avatar_widget.dart';
import '../models/comment_model.dart';
import 'glass_card.dart';
import 'hud_button.dart';

class FeedbackThreadWidget extends StatelessWidget {
  final List<CommentModel> comments;
  final void Function(CommentModel) onReply;

  const FeedbackThreadWidget({
    super.key,
    required this.comments,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
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
                                color: const Color(0xFF92FFFFFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeago.format(comment.createdAt.toDate()),
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF45FFFFFF),
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
                    padding: const EdgeInsets.only(
                      left: 52,
                    ), // Align with content above
                    child: Text(
                      comment.content,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF70FFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 52,
                    ), // Align with content above
                    child: Row(
                      children: [
                        HudButton(
                          onPressed: () => onReply(comment),
                          text: 'reply'.tr(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            comment.type,
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
}
