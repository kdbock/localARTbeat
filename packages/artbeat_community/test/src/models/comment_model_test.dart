import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_community/models/comment_model.dart';

void main() {
  group('CommentModel', () {
    test('toFirestore omits null fields and serializes moderation status', () {
      final model = CommentModel(
        id: 'c1',
        postId: 'p1',
        userId: 'u1',
        content: 'Great work!',
        parentCommentId: '',
        type: 'Appreciation',
        createdAt: Timestamp.now(),
        userName: 'User One',
        userAvatarUrl: 'https://example.com/u1.jpg',
      );

      final map = model.toFirestore();

      expect(map['moderationStatus'], 'approved');
      expect(map.containsKey('flaggedAt'), isFalse);
      expect(map.containsKey('moderationNotes'), isFalse);
    });

    test('fromFirestore restores flagged state and timestamps', () async {
      final firestore = FakeFirebaseFirestore();
      final flaggedAt = Timestamp.fromDate(DateTime.now());

      await firestore.collection('comments').doc('c2').set({
        'postId': 'p1',
        'userId': 'u2',
        'content': 'Needs review',
        'parentCommentId': '',
        'type': 'Question',
        'createdAt': Timestamp.now(),
        'userName': 'User Two',
        'userAvatarUrl': 'https://example.com/u2.jpg',
        'moderationStatus': 'flagged',
        'flagged': true,
        'flaggedAt': flaggedAt,
      });

      final doc = await firestore.collection('comments').doc('c2').get();
      final model = CommentModel.fromFirestore(doc);

      expect(model.id, 'c2');
      expect(model.moderationStatus, CommentModerationStatus.flagged);
      expect(model.flagged, isTrue);
      expect(model.flaggedAt, isNotNull);
    });
  });
}
