import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_admin/src/models/recent_activity_model.dart';
import 'package:artbeat_admin/src/services/recent_activity_service.dart';

void main() {
  group('RecentActivityService', () {
    late FakeFirebaseFirestore firestore;
    late RecentActivityService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = RecentActivityService(firestore: firestore);
    });

    test('createActivity writes recent activity document', () async {
      await service.createActivity(
        type: ActivityType.adminAction,
        title: 'Manual Review',
        description: 'Moderator reviewed flagged post',
        userId: 'admin-1',
      );

      final snapshot = await firestore.collection('recent_activities').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['title'], 'Manual Review');
    });

    test('getActivityStats returns count grouped by type', () async {
      await firestore.collection('recent_activities').add({
        'type': ActivityType.userRegistered.name,
        'title': 'U1',
        'description': 'new user',
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
      await firestore.collection('recent_activities').add({
        'type': ActivityType.userRegistered.name,
        'title': 'U2',
        'description': 'new user',
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
      await firestore.collection('recent_activities').add({
        'type': ActivityType.adminAction.name,
        'title': 'A1',
        'description': 'action',
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      final stats = await service.getActivityStats();

      expect(stats[ActivityType.userRegistered.name], 2);
      expect(stats[ActivityType.adminAction.name], 1);
    });

    test('cleanupOldActivities removes records older than cutoff', () async {
      await firestore.collection('recent_activities').add({
        'type': ActivityType.systemError.name,
        'title': 'Old',
        'description': 'old error',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 40)),
        ),
      });
      await firestore.collection('recent_activities').add({
        'type': ActivityType.systemError.name,
        'title': 'New',
        'description': 'new error',
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      await service.cleanupOldActivities(daysToKeep: 30);

      final remaining = await firestore.collection('recent_activities').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.data()['title'], 'New');
    });
  });
}
