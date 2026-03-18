import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_admin/src/utils/user_activity_utils.dart';

void main() {
  group('user_activity_utils', () {
    test('prefers the more recent activity timestamp', () {
      final data = <String, dynamic>{
        'lastActive': Timestamp.fromDate(DateTime(2026, 3, 18, 10)),
        'lastActiveAt': Timestamp.fromDate(DateTime(2026, 3, 18, 8)),
      };

      expect(
        getEffectiveLastActive(data),
        DateTime(2026, 3, 18, 10),
      );
    });

    test('falls back to lastActiveAt when lastActive is missing', () {
      final data = <String, dynamic>{
        'lastActiveAt': Timestamp.fromDate(DateTime(2026, 3, 18, 8)),
      };

      expect(
        getEffectiveLastActive(data),
        DateTime(2026, 3, 18, 8),
      );
    });

    test('range check is inclusive at start and exclusive at end', () {
      final start = DateTime(2026, 3, 18);
      final end = DateTime(2026, 3, 19);

      expect(
        isWithinRange(start, start: start, end: end),
        isTrue,
      );
      expect(
        isWithinRange(end, start: start, end: end),
        isFalse,
      );
    });
  });
}
