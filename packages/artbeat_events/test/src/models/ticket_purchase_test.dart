import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_events/src/models/ticket_purchase.dart';

void main() {
  group('TicketPurchase', () {
    test('create sets status by amount and formats amount', () {
      final freePurchase = TicketPurchase.create(
        eventId: 'e1',
        ticketTypeId: 'free',
        userId: 'u1',
        userEmail: 'u1@example.com',
        userName: 'User One',
        quantity: 1,
        totalAmount: 0,
      );
      final paidPurchase = TicketPurchase.create(
        eventId: 'e1',
        ticketTypeId: 'paid',
        userId: 'u2',
        userEmail: 'u2@example.com',
        userName: 'User Two',
        quantity: 2,
        totalAmount: 40,
      );

      expect(freePurchase.status, TicketPurchaseStatus.confirmed);
      expect(freePurchase.formattedAmount, 'Free');
      expect(paidPurchase.status, TicketPurchaseStatus.pending);
      expect(paidPurchase.formattedAmount, r'$40.00');
    });

    test(
      'toFirestore/fromFirestore round-trip preserves core fields',
      () async {
        final firestore = FakeFirebaseFirestore();
        final purchase = TicketPurchase.create(
          eventId: 'event-1',
          ticketTypeId: 'vip',
          userId: 'user-1',
          userEmail: 'user@example.com',
          userName: 'User',
          quantity: 3,
          totalAmount: 120,
          paymentIntentId: 'pi_123',
        ).copyWith(status: TicketPurchaseStatus.confirmed);

        final ref = await firestore
            .collection('ticket_purchases')
            .add(purchase.toFirestore());
        final doc = await firestore
            .collection('ticket_purchases')
            .doc(ref.id)
            .get();

        final restored = TicketPurchase.fromFirestore(doc);
        expect(restored.id, ref.id);
        expect(restored.eventId, 'event-1');
        expect(restored.ticketTypeId, 'vip');
        expect(restored.status, TicketPurchaseStatus.confirmed);
        expect(restored.quantity, 3);
        expect(restored.paymentIntentId, 'pi_123');
        expect(
          restored.qrCodeData,
          'artbeat://ticket/${ref.id}/event-1/user-1',
        );
      },
    );
  });
}
