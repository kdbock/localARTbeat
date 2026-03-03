import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_events/src/models/ticket_type.dart';

void main() {
  group('TicketType', () {
    test('toMap omits null values and preserves key fields', () {
      const ticket = TicketType(
        id: 't1',
        name: 'General Admission',
        category: TicketCategory.paid,
        price: 20,
        quantity: 50,
      );

      final map = ticket.toMap();

      expect(map['id'], 't1');
      expect(map['category'], 'paid');
      expect(map.containsKey('metadata'), isFalse);
      expect(map.containsKey('saleStartDate'), isFalse);
      expect(map.containsKey('saleEndDate'), isFalse);
    });

    test('fromMap defaults unknown category to free', () {
      final ticket = TicketType.fromMap({
        'id': 't2',
        'name': 'Mystery',
        'category': 'unmapped',
        'price': 0,
        'quantity': 10,
      });

      expect(ticket.category, TicketCategory.free);
      expect(ticket.isFree, isTrue);
    });

    test('availability honors sale windows and remaining quantity', () {
      final now = DateTime.now();
      final availableTicket = TicketType.paid(
        id: 'a',
        name: 'A',
        price: 10,
        quantity: 5,
        quantitySold: 1,
        saleStartDate: now.subtract(const Duration(minutes: 5)),
        saleEndDate: now.add(const Duration(minutes: 5)),
      );
      final futureTicket = TicketType.paid(
        id: 'b',
        name: 'B',
        price: 10,
        quantity: 5,
        saleStartDate: now.add(const Duration(days: 1)),
      );
      final soldOutTicket = TicketType.paid(
        id: 'c',
        name: 'C',
        price: 10,
        quantity: 2,
        quantitySold: 2,
      );

      expect(availableTicket.isAvailable, isTrue);
      expect(futureTicket.isAvailable, isFalse);
      expect(soldOutTicket.isAvailable, isFalse);
      expect(soldOutTicket.isSoldOut, isTrue);
    });
  });
}
