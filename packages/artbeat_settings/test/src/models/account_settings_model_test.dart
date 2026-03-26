import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_settings/src/models/account_settings_model.dart';

void main() {
  group('AccountSettingsModel', () {
    test('fromMap accepts legacy fullName and timestamp fields', () {
      final createdAt = Timestamp.fromDate(DateTime(2026, 1, 2, 3, 4, 5));
      final updatedAt = Timestamp.fromDate(DateTime(2026, 2, 3, 4, 5, 6));

      final model = AccountSettingsModel.fromMap({
        'userId': 'user-1',
        'email': 'artist@example.com',
        'username': 'artist1',
        'fullName': 'Artist One',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'bio': 'Painter',
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      });

      expect(model.userId, 'user-1');
      expect(model.displayName, 'Artist One');
      expect(model.profileImageUrl, 'https://example.com/profile.jpg');
      expect(model.createdAt, createdAt.toDate());
      expect(model.updatedAt, updatedAt.toDate());
    });

    test('toMap preserves displayName for settings payloads', () {
      final model = AccountSettingsModel(
        userId: 'user-2',
        email: 'user2@example.com',
        username: 'user2',
        displayName: 'User Two',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final map = model.toMap();

      expect(map['displayName'], 'User Two');
      expect(map['username'], 'user2');
      expect(map['email'], 'user2@example.com');
    });
  });
}
