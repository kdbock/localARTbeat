import 'package:artbeat_artist/src/models/subscription_model.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier;
import 'package:flutter_test/flutter_test.dart';

void main() {
  SubscriptionModel build({DateTime? endDate, DateTime? canceledAt}) {
    return SubscriptionModel(
      id: 'sub-1',
      userId: 'user-1',
      tier: SubscriptionTier.creator,
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: endDate,
      autoRenew: true,
      canceledAt: canceledAt,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    );
  }

  group('SubscriptionModel', () {
    test('active subscription has active status', () {
      final model = build(
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(model.isActive, isTrue);
      expect(model.status, 'active');
      expect(model.daysRemaining, greaterThanOrEqualTo(29));
    });

    test('canceled with future end date is grace period and inactive', () {
      final model = build(
        endDate: DateTime.now().add(const Duration(days: 10)),
        canceledAt: DateTime.now(),
      );
      expect(model.isActive, isFalse);
      expect(model.isGracePeriod, isTrue);
      expect(model.status, 'inactive');
    });

    test('expired subscription has zero days remaining', () {
      final model = build(
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(model.isActive, isFalse);
      expect(model.daysRemaining, 0);
    });
  });
}
