import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_messaging/src/models/message_reaction_model.dart';

void main() {
  group('MessageReactionModel', () {
    test('create builds deterministic id and positivity flags', () {
      final reaction = MessageReactionModel.create(
        messageId: 'm1',
        chatId: 'c1',
        userId: 'u1',
        userName: 'User One',
        reactionType: ReactionTypes.like,
        emoji: ReactionTypes.getEmoji(ReactionTypes.like),
      );

      expect(reaction.id, 'm1_u1_like');
      expect(reaction.isPositive, isTrue);
      expect(reaction.isNegative, isFalse);
    });

    test('summary aggregates counts and user reaction lookup', () {
      final r1 = MessageReactionModel.create(
        messageId: 'm1',
        chatId: 'c1',
        userId: 'u1',
        userName: 'User One',
        reactionType: ReactionTypes.like,
        emoji: '👍',
      );
      final r2 = MessageReactionModel.create(
        messageId: 'm1',
        chatId: 'c1',
        userId: 'u2',
        userName: 'User Two',
        reactionType: ReactionTypes.like,
        emoji: '👍',
      );
      final r3 = MessageReactionModel.create(
        messageId: 'm1',
        chatId: 'c1',
        userId: 'u3',
        userName: 'User Three',
        reactionType: ReactionTypes.sad,
        emoji: '😢',
      );

      final summary = MessageReactionsSummary.fromReactions('m1', [r1, r2, r3]);

      expect(summary.totalReactions, 3);
      expect(summary.getCount(ReactionTypes.like), 2);
      expect(summary.hasUserReacted('u1', ReactionTypes.like), isTrue);
      expect(summary.getUserReaction('u2', ReactionTypes.like), isNotNull);
      expect(summary.mostPopularReaction, ReactionTypes.like);
    });
  });
}
