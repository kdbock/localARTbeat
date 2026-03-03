import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_profile/src/models/profile_connection_model.dart';

void main() {
  group('ProfileConnectionModel', () {
    test('connectionReasonText formats mutual follower reason', () {
      final model = ProfileConnectionModel(
        id: 'c1',
        userId: 'u1',
        connectedUserId: 'u2',
        connectedUserName: 'Taylor',
        connectionType: 'mutual_follower',
        mutualFollowersCount: 3,
        createdAt: DateTime.now(),
      );

      expect(model.connectionReasonText, '3 mutual followers');
    });

    test('isHighPriority based on score or mutual count', () {
      final byScore = ProfileConnectionModel(
        id: 'c2',
        userId: 'u1',
        connectedUserId: 'u3',
        connectedUserName: 'Jordan',
        connectionType: 'suggestion',
        connectionScore: 0.8,
        createdAt: DateTime.now(),
      );
      final byMutualCount = ProfileConnectionModel(
        id: 'c3',
        userId: 'u1',
        connectedUserId: 'u4',
        connectedUserName: 'Sam',
        connectionType: 'suggestion',
        mutualFollowersCount: 6,
        createdAt: DateTime.now(),
      );

      expect(byScore.isHighPriority, isTrue);
      expect(byMutualCount.isHighPriority, isTrue);
    });
  });
}
