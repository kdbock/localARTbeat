import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_community/models/post_model.dart';

void main() {
  group('PostModel', () {
    test('toFirestore/fromFirestore preserves core fields', () async {
      final firestore = FakeFirebaseFirestore();
      final model = PostModel(
        id: 'ignore',
        userId: 'u1',
        userName: 'User One',
        userPhotoUrl: 'https://example.com/u1.jpg',
        content: 'Hello community',
        imageUrls: const ['https://example.com/p1.jpg'],
        tags: const ['art', 'digital'],
        location: 'NYC',
        createdAt: DateTime.now(),
        moderationStatus: PostModerationStatus.approved,
        flagged: false,
      );

      final ref = await firestore.collection('posts').add(model.toFirestore());
      final doc = await firestore.collection('posts').doc(ref.id).get();
      final restored = PostModel.fromFirestore(doc);

      expect(restored.id, ref.id);
      expect(restored.userId, 'u1');
      expect(restored.content, 'Hello community');
      expect(restored.tags, contains('art'));
      expect(restored.moderationStatus, PostModerationStatus.approved);
    });

    test('fromString handles underReview normalization', () {
      expect(
        PostModerationStatus.fromString('underReview'),
        PostModerationStatus.underReview,
      );
      expect(
        PostModerationStatus.fromString('UNDERREVIEW'),
        PostModerationStatus.underReview,
      );
    });
  });
}
