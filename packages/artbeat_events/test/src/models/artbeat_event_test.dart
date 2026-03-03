import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_events/src/models/artbeat_event.dart';
import 'package:artbeat_events/src/models/ticket_type.dart';

void main() {
  ArtbeatEvent buildEvent({
    DateTime? dateTime,
    List<TicketType>? tickets,
    int maxAttendees = 100,
  }) {
    return ArtbeatEvent.create(
      title: 'City Art Walk',
      description: 'Guided walk through downtown murals',
      artistId: 'artist-1',
      imageUrls: const ['https://example.com/1.jpg'],
      artistHeadshotUrl: 'https://example.com/headshot.jpg',
      eventBannerUrl: 'https://example.com/banner.jpg',
      dateTime: dateTime ?? DateTime.now().add(const Duration(days: 5)),
      location: 'Downtown',
      ticketTypes:
          tickets ??
          [
            TicketType.free(
              id: 'free',
              name: 'Free Entry',
              quantity: 80,
              quantitySold: 10,
            ),
            TicketType.paid(
              id: 'paid',
              name: 'Supporter',
              price: 20,
              quantity: 20,
              quantitySold: 5,
            ),
          ],
      contactEmail: 'artist@example.com',
      maxAttendees: maxAttendees,
      category: 'Tour',
    );
  }

  group('ArtbeatEvent computed properties', () {
    test('computes sold/available tickets and free/paid flags', () {
      final event = buildEvent();

      expect(event.totalAvailableTickets, 100);
      expect(event.totalTicketsSold, 15);
      expect(event.hasFreeTickets, isTrue);
      expect(event.hasPaidTickets, isTrue);
      expect(event.isSoldOut, isFalse);
      expect(event.hasEnded, isFalse);
    });

    test('detects sold out when sold reaches max attendees', () {
      final event = buildEvent(
        maxAttendees: 15,
        tickets: const [
          TicketType(
            id: 'a',
            name: 'A',
            category: TicketCategory.paid,
            price: 10,
            quantity: 15,
            quantitySold: 15,
          ),
        ],
      );

      expect(event.isSoldOut, isTrue);
    });

    test('copyWith preserves id and overrides requested fields', () {
      final event = buildEvent();
      final updated = event.copyWith(
        title: 'Updated Title',
        location: 'Uptown',
      );

      expect(updated.id, event.id);
      expect(updated.title, 'Updated Title');
      expect(updated.location, 'Uptown');
      expect(updated.artistId, event.artistId);
    });
  });
}
