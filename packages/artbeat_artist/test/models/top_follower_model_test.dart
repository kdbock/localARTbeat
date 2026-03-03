import 'package:artbeat_artist/src/models/top_follower_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TopFollowerModel', () {
    test('copyWith overrides selected values', () {
      final original = TopFollowerModel(
        followerId: 'u1',
        followerName: 'Follower',
        engagementScore: 10,
        lastEngagementAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        followerName: 'Updated',
        engagementScore: 25,
      );

      expect(updated.followerId, 'u1');
      expect(updated.followerName, 'Updated');
      expect(updated.engagementScore, 25);
      expect(updated.lastEngagementAt, DateTime(2026, 1, 1));
    });

    test('toMap/fromMap round trip keeps core fields', () {
      final model = TopFollowerModel(
        followerId: 'u2',
        followerName: 'Name',
        engagementScore: 33,
        giftCount: 2,
        likeCount: 4,
        messageCount: 1,
        viewCount: 10,
        lastEngagementAt: DateTime(2026, 2, 2),
        isVerified: true,
      );

      final parsed = TopFollowerModel.fromMap(model.toMap());
      expect(parsed.followerId, 'u2');
      expect(parsed.engagementScore, 33);
      expect(parsed.isVerified, isTrue);
    });
  });
}
