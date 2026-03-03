import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:artbeat_events/src/models/artbeat_event.dart';
import 'package:artbeat_events/src/models/ticket_purchase.dart';
import 'package:artbeat_events/src/models/ticket_type.dart';
import 'package:artbeat_events/src/services/event_service.dart';
import 'package:artbeat_events/src/services/recurring_event_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeUser extends Fake implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;
}

class _MockRecurringEventService extends Mock implements RecurringEventService {}

void main() {
  ArtbeatEvent event0({DateTime? dateTime}) {
    return ArtbeatEvent.create(
      title: 'Live Painting Session',
      description: 'Interactive painting night',
      artistId: 'artist-42',
      imageUrls: const ['https://example.com/event.jpg'],
      artistHeadshotUrl: 'https://example.com/artist.jpg',
      eventBannerUrl: 'https://example.com/banner.jpg',
      dateTime: dateTime ?? DateTime.now().add(const Duration(days: 1)),
      location: 'Studio 12',
      ticketTypes: const [
        TicketType(
          id: 'general',
          name: 'General',
          category: TicketCategory.paid,
          price: 15,
          quantity: 50,
          quantitySold: 0,
        ),
      ],
      contactEmail: 'artist@example.com',
      category: 'Workshop',
    );
  }

  group('EventService', () {
    late FakeFirebaseFirestore firestore;
    late _MockFirebaseAuth auth;
    late _MockRecurringEventService recurringService;
    late EventService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = _MockFirebaseAuth();
      recurringService = _MockRecurringEventService();
      service = EventService(
        firestore: firestore,
        auth: auth,
        recurringEventService: recurringService,
      );
    });

    test('createEvent persists and returns generated document id', () async {
      final event = event0();

      final id = await service.createEvent(event);

      expect(id, isNotEmpty);
      final doc = await firestore.collection('events').doc(id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], 'Live Painting Session');
      expect(doc.data()!['artistId'], 'artist-42');
    });

    test('getEvent returns null for unknown event id', () async {
      final result = await service.getEvent('does-not-exist');
      expect(result, isNull);
    });

    test('getEvent returns mapped ArtbeatEvent for existing document', () async {
      final event = event0();
      final docRef = await firestore.collection('events').add(event.toFirestore());

      final loaded = await service.getEvent(docRef.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, docRef.id);
      expect(loaded.title, event.title);
      expect(loaded.location, event.location);
    });

    test('searchEvents filters by title/description/location and sorts by date', () async {
      final now = DateTime.now();
      final e1 = event0(dateTime: now.add(const Duration(days: 3))).copyWith(
        title: 'Street Art Jam',
        description: 'Downtown jam session',
        location: 'Downtown',
      );
      final e2 = event0(dateTime: now.add(const Duration(days: 1))).copyWith(
        title: 'Gallery Night',
        description: 'Street artists meetup',
        location: 'Midtown',
      );
      final e3 = event0(dateTime: now.add(const Duration(days: 2))).copyWith(
        title: 'Portrait Basics',
        description: 'Beginner course',
        location: 'Uptown',
      );

      await firestore.collection('events').add(e1.toFirestore());
      await firestore.collection('events').add(e2.toFirestore());
      await firestore.collection('events').add(e3.toFirestore());

      final results = await service.searchEvents('street');

      expect(results.length, 2);
      // Title match should rank first.
      expect(results.first.title, 'Street Art Jam');
    });

    test('purchaseTickets throws when no authenticated user', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        () => service.purchaseTickets(
          eventId: 'event-1',
          ticketTypeId: 'general',
          quantity: 1,
          userEmail: 'user@example.com',
          userName: 'User',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('purchaseTickets creates purchase and updates attendee/ticket counts', () async {
      final user = _FakeUser('user-123');
      when(auth.currentUser).thenReturn(user);

      final event = event0().copyWith(
        id: 'event-123',
        ticketTypes: const [
          TicketType(
            id: 'general',
            name: 'General',
            category: TicketCategory.paid,
            price: 15,
            quantity: 5,
            quantitySold: 1,
          ),
        ],
      );
      await firestore.collection('events').doc('event-123').set(event.toFirestore());

      final purchaseId = await service.purchaseTickets(
        eventId: 'event-123',
        ticketTypeId: 'general',
        quantity: 2,
        userEmail: 'user@example.com',
        userName: 'Test User',
      );

      expect(purchaseId, isNotEmpty);

      final purchaseDoc =
          await firestore.collection('ticket_purchases').doc(purchaseId).get();
      expect(purchaseDoc.exists, isTrue);
      expect(purchaseDoc.data()!['userId'], 'user-123');
      expect(purchaseDoc.data()!['quantity'], 2);

      final eventDoc = await firestore.collection('events').doc('event-123').get();
      final attendeeIds = (eventDoc.data()!['attendeeIds'] as List<dynamic>).cast<String>();
      expect(attendeeIds.contains('user-123'), isTrue);

      final ticketTypes =
          (eventDoc.data()!['ticketTypes'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final generalTicket = ticketTypes.firstWhere((t) => t['id'] == 'general');
      expect(generalTicket['quantitySold'], 3);
    });

    test('purchaseTickets throws when ticket type does not exist', () async {
      final user = _FakeUser('user-123');
      when(auth.currentUser).thenReturn(user);

      final event = event0().copyWith(id: 'event-404');
      await firestore.collection('events').doc('event-404').set(event.toFirestore());

      await expectLater(
        () => service.purchaseTickets(
          eventId: 'event-404',
          ticketTypeId: 'vip-missing',
          quantity: 1,
          userEmail: 'user@example.com',
          userName: 'User',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getEvents returns only purchased events when onlyMyTickets=true', () async {
      final user = _FakeUser('user-7');
      when(auth.currentUser).thenReturn(user);

      final eventA = event0().copyWith(id: 'event-a');
      final eventB = event0().copyWith(
        id: 'event-b',
        title: 'Another Event',
        dateTime: DateTime.now().add(const Duration(days: 2)),
      );

      await firestore.collection('events').doc('event-a').set(eventA.toFirestore());
      await firestore.collection('events').doc('event-b').set(eventB.toFirestore());

      await firestore.collection('ticket_purchases').add({
        'eventId': 'event-b',
        'userId': 'user-7',
        'ticketTypeId': 'general',
        'userEmail': 'user@example.com',
        'userName': 'User',
        'quantity': 1,
        'totalAmount': 15.0,
        'status': 'confirmed',
        'purchaseDate': DateTime.now(),
      });

      final results = await service.getEvents(onlyMyTickets: true);

      expect(results.length, 1);
      expect(results.first.id, 'event-b');
    });

    test('refundTicketPurchase marks refunded and decreases sold quantity', () async {
      final event = event0(
        dateTime: DateTime.now().add(const Duration(days: 7)),
      ).copyWith(
        id: 'event-r1',
        ticketTypes: const [
          TicketType(
            id: 'general',
            name: 'General',
            category: TicketCategory.paid,
            price: 15,
            quantity: 10,
            quantitySold: 5,
          ),
        ],
      );
      await firestore.collection('events').doc('event-r1').set(event.toFirestore());

      final purchase = TicketPurchase.create(
        eventId: 'event-r1',
        ticketTypeId: 'general',
        userId: 'user-1',
        userEmail: 'u@example.com',
        userName: 'User',
        quantity: 2,
        totalAmount: 30,
      ).copyWith(status: TicketPurchaseStatus.confirmed);

      final purchaseRef = await firestore
          .collection('ticket_purchases')
          .add(purchase.toFirestore());

      await service.refundTicketPurchase(purchaseRef.id, 'refund-abc');

      final purchaseDoc = await firestore
          .collection('ticket_purchases')
          .doc(purchaseRef.id)
          .get();
      expect(purchaseDoc.data()!['status'], TicketPurchaseStatus.refunded.name);
      expect(purchaseDoc.data()!['refundId'], 'refund-abc');

      final eventDoc = await firestore.collection('events').doc('event-r1').get();
      final ticketTypes =
          (eventDoc.data()!['ticketTypes'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final updatedGeneral = ticketTypes.firstWhere((t) => t['id'] == 'general');
      expect(updatedGeneral['quantitySold'], 3);
    });
  });
}
