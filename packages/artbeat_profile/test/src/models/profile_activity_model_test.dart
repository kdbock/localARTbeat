import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_profile/src/models/profile_activity_model.dart';

void main() {
  group('ProfileActivityModel', () {
    test('activityDisplayText maps known activity types', () {
      final activity = ProfileActivityModel(
        id: 'a1',
        userId: 'u1',
        activityType: 'follow',
        targetUserName: 'Alex',
        createdAt: DateTime.now(),
      );

      expect(activity.activityDisplayText, 'Alex started following you');
    });

    test('toFirestore/fromFirestore round-trip keeps core fields', () async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      final model = ProfileActivityModel(
        id: 'ignored',
        userId: 'u1',
        activityType: 'profile_view',
        targetUserId: 'u2',
        targetUserName: 'Viewer',
        createdAt: now,
        isRead: false,
      );

      final ref = await firestore
          .collection('profile_activities')
          .add(model.toFirestore());
      final doc = await firestore
          .collection('profile_activities')
          .doc(ref.id)
          .get();
      final restored = ProfileActivityModel.fromFirestore(doc);

      expect(restored.id, ref.id);
      expect(restored.userId, 'u1');
      expect(restored.activityType, 'profile_view');
      expect(restored.targetUserId, 'u2');
      expect(restored.isRead, isFalse);
      expect(restored.createdAt, isA<DateTime>());
      expect(doc.data()!['createdAt'], isA<Timestamp>());
    });
  });
}
