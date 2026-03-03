import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_community/services/moderation_service.dart';

void main() {
  group('ModerationService', () {
    late FakeFirebaseFirestore firestore;
    late ModerationService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ModerationService(firestore: firestore);
    });

    test('checkContent flags profanity and spam patterns', () {
      final result = service.checkContent(
        'THIS IS AMAZING!!!! visit http://spam.example for damn deals',
      );

      expect(result.shouldFlag, isTrue);
      expect(result.violations, isNotEmpty);
      expect(result.recommendedAction, isA<ModerationAction>());
    });

    test('checkContent reports short content for empty text', () {
      final result = service.checkContent('   ');

      expect(result.shouldFlag, isTrue);
      expect(
        result.violations.any((v) => v.type == ModerationViolationType.shortContent),
        isTrue,
      );
    });

    test('getModerationStats counts flagged posts/comments', () async {
      await firestore.collection('posts').doc('p1').set({'flagged': true});
      await firestore.collection('posts').doc('p2').set({'flagged': false});
      await firestore.collection('comments').doc('c1').set({'flagged': true});
      await firestore.collection('comments').doc('c2').set({'flagged': true});

      final stats = await service.getModerationStats();

      expect(stats.totalPosts, 2);
      expect(stats.totalComments, 2);
      expect(stats.flaggedPosts, 1);
      expect(stats.flaggedComments, 2);
      expect(stats.pendingModeration, 3);
    });
  });
}
