import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_profile/src/models/profile_customization_model.dart';

void main() {
  group('ProfileCustomizationModel', () {
    test('copyWith preserves userId and updates requested fields', () {
      final model = ProfileCustomizationModel(
        userId: 'u1',
        selectedTheme: 'default',
        primaryColor: '#00fd8a',
        secondaryColor: '#8c52ff',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = model.copyWith(
        selectedTheme: 'dark',
        showBio: false,
      );

      expect(updated.userId, 'u1');
      expect(updated.selectedTheme, 'dark');
      expect(updated.showBio, isFalse);
      expect(updated.primaryColor, '#00fd8a');
    });

    test('toFirestore/fromFirestore round-trip works with document id', () async {
      final firestore = FakeFirebaseFirestore();
      final now = DateTime.now();
      final model = ProfileCustomizationModel(
        userId: 'u2',
        selectedTheme: 'default',
        layoutStyle: 'grid',
        visibilitySettings: const {'showEmail': false},
        createdAt: now,
        updatedAt: now,
      );

      await firestore
          .collection('profile_customization')
          .doc('u2')
          .set(model.toFirestore());
      final doc = await firestore.collection('profile_customization').doc('u2').get();
      final restored = ProfileCustomizationModel.fromFirestore(doc);

      expect(restored.userId, 'u2');
      expect(restored.layoutStyle, 'grid');
      expect(restored.visibilitySettings['showEmail'], isFalse);
    });
  });
}
