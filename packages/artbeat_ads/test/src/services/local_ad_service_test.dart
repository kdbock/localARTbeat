import 'package:artbeat_ads/src/models/local_ad.dart';
import 'package:artbeat_ads/src/models/local_ad_size.dart';
import 'package:artbeat_ads/src/models/local_ad_status.dart';
import 'package:artbeat_ads/src/models/local_ad_zone.dart';
import 'package:artbeat_ads/src/services/local_ad_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  group('LocalAdService moderation/admin seams', () {
    test('getAdsForReview returns only pending and flagged ads', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'admin_1', email: 'admin@example.com'),
        signedIn: true,
      );
      final service = LocalAdService(
        firestore: firestore,
        auth: auth,
        storage: _MockFirebaseStorage(),
      );
      final now = DateTime.now().toUtc();

      await firestore.collection('localAds').doc('pending_ad').set({
        'userId': 'u1',
        'title': 'Pending',
        'description': 'Needs moderation',
        'zone': LocalAdZone.community.index,
        'size': LocalAdSize.small.index,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'status': LocalAdStatus.pendingReview.index,
        'reportCount': 0,
      });
      await firestore.collection('localAds').doc('flagged_ad').set({
        'userId': 'u2',
        'title': 'Flagged',
        'description': 'Reported ad',
        'zone': LocalAdZone.events.index,
        'size': LocalAdSize.big.index,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'status': LocalAdStatus.flagged.index,
        'reportCount': 3,
      });
      await firestore.collection('localAds').doc('active_ad').set({
        'userId': 'u3',
        'title': 'Active',
        'description': 'Should not appear in review queue',
        'zone': LocalAdZone.artists.index,
        'size': LocalAdSize.small.index,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'status': LocalAdStatus.active.index,
        'reportCount': 0,
      });

      final reviewAds = await service.getAdsForReview();
      final ids = reviewAds.map((ad) => ad.id).toList();

      expect(ids, containsAll(<String>['pending_ad', 'flagged_ad']));
      expect(ids, isNot(contains('active_ad')));
    });

    test('updateAdStatus persists moderation metadata', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'admin_2', email: 'admin2@example.com'),
        signedIn: true,
      );
      final service = LocalAdService(
        firestore: firestore,
        auth: auth,
        storage: _MockFirebaseStorage(),
      );
      final now = DateTime.now().toUtc();

      await firestore.collection('localAds').doc('ad_123').set({
        'userId': 'u1',
        'title': 'Review Me',
        'description': 'Pending review',
        'zone': LocalAdZone.community.index,
        'size': LocalAdSize.small.index,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'status': LocalAdStatus.pendingReview.index,
        'reportCount': 1,
      });

      await service.updateAdStatus(
        adId: 'ad_123',
        status: LocalAdStatus.rejected,
        adminId: 'admin_2',
        rejectionReason: 'Disallowed claims',
      );

      final updated = await firestore.collection('localAds').doc('ad_123').get();
      final data = updated.data()!;

      expect(data['status'], LocalAdStatus.rejected.index);
      expect(data['reviewedBy'], 'admin_2');
      expect(data['rejectionReason'], 'Disallowed claims');
      expect(data['reviewedAt'], isA<Timestamp>());
    });
  });

  group('LocalAdService.createPurchasedAd', () {
    test(
      'records recovery document when purchase verification cannot run on current platform',
      () async {
        final firestore = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'user_123', email: 'owner@example.com'),
          signedIn: true,
        );
        final service = LocalAdService(
          firestore: firestore,
          auth: auth,
          storage: _MockFirebaseStorage(),
        );

        final ad = LocalAd(
          id: '',
          userId: 'user_123',
          title: 'Studio Spotlight',
          description: 'Promote local studio classes.',
          zone: LocalAdZone.community,
          size: LocalAdSize.small,
          createdAt: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
          subscriptionProductId: 'ad_monthly_basic',
          purchaseId: 'purchase_001',
          transactionId: 'txn_001',
        );

        final result = await service.createPurchasedAd(
          ad: ad,
          verificationData: 'token_abc123',
        );

        expect(result.adId, isNull);
        expect(result.recoveryId, isNotNull);

        final recoveryDoc = await firestore
            .collection('localAdPurchaseRecoveries')
            .doc(result.recoveryId)
            .get();
        expect(recoveryDoc.exists, isTrue);

        final data = recoveryDoc.data()!;
        expect(data['userId'], 'user_123');
        expect(data['status'], 'pending_manual_recovery');
        expect(data['purchaseId'], 'purchase_001');
        expect(data['transactionId'], 'txn_001');
        expect(data['subscriptionProductId'], 'ad_monthly_basic');
        expect(data['error'] as String, contains('Unsupported platform'));
      },
    );
  });
}
