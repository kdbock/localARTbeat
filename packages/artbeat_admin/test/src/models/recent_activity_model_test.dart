import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_admin/src/models/recent_activity_model.dart';

void main() {
  group('RecentActivityModel', () {
    test('ActivityType.fromString maps known and unknown values', () {
      expect(
        ActivityType.fromString('user_registered'),
        ActivityType.userRegistered,
      );
      expect(ActivityType.fromString('unknown_type'), ActivityType.adminAction);
    });

    test('toDocument stores enum name and timestamp', () {
      final model = RecentActivityModel(
        id: 'a1',
        type: ActivityType.systemError,
        title: 'System Error',
        description: 'Timeout',
        timestamp: DateTime.now(),
        metadata: const {'code': 'TIMEOUT'},
      );

      final map = model.toDocument();
      expect(map['type'], ActivityType.systemError.name);
      expect(map['timestamp'], isNotNull);
      expect(map['metadata']['code'], 'TIMEOUT');
    });

    test('timeAgo returns Just now for near current timestamps', () {
      final model = RecentActivityModel(
        id: 'a2',
        type: ActivityType.adminAction,
        title: 'Action',
        description: 'Did something',
        timestamp: DateTime.now(),
      );

      expect(model.timeAgo, 'Just now');
    });
  });
}
