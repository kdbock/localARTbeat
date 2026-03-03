import 'package:artbeat_artwork/src/models/auction_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuctionStatus', () {
    test('fromString maps valid values and defaults to open', () {
      expect(AuctionStatus.fromString('open'), AuctionStatus.open);
      expect(AuctionStatus.fromString('closed'), AuctionStatus.closed);
      expect(AuctionStatus.fromString('paid'), AuctionStatus.paid);
      expect(AuctionStatus.fromString('invalid'), AuctionStatus.open);
    });

    test('value returns persisted string', () {
      expect(AuctionStatus.open.value, 'open');
      expect(AuctionStatus.closed.value, 'closed');
      expect(AuctionStatus.paid.value, 'paid');
    });
  });
}
