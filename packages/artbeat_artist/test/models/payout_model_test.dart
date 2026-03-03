import 'package:artbeat_artist/src/models/payout_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayoutModel', () {
    test('status helpers match status value', () {
      final pending = PayoutModel(
        id: 'p1',
        artistId: 'a1',
        amount: 50,
        status: 'pending',
        requestedAt: DateTime.now(),
        payoutMethod: 'bank_account',
        accountId: 'acct_1',
      );
      final completed = PayoutModel(
        id: 'p2',
        artistId: 'a1',
        amount: 50,
        status: 'completed',
        requestedAt: DateTime.now(),
        payoutMethod: 'bank_account',
        accountId: 'acct_1',
      );

      expect(pending.isPending, isTrue);
      expect(pending.isCompleted, isFalse);
      expect(completed.isCompleted, isTrue);
      expect(completed.isFailed, isFalse);
    });
  });

  group('PayoutAccountModel', () {
    test('displayName masks bank account numbers', () {
      final model = PayoutAccountModel(
        id: 'acct',
        artistId: 'artist',
        accountType: 'bank_account',
        accountHolderName: 'A',
        bankName: 'Test Bank',
        accountNumber: '1234567890',
        routingNumber: '111111111',
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
      );

      expect(model.displayName, 'Test Bank - ****7890');
    });

    test('displayName uses paypal email when accountType is paypal', () {
      final model = PayoutAccountModel(
        id: 'acct2',
        artistId: 'artist',
        accountType: 'paypal',
        accountHolderName: 'A',
        accountNumber: '',
        routingNumber: '',
        paypalEmail: 'artist@example.com',
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
      );

      expect(model.displayName, 'PayPal - artist@example.com');
    });
  });
}
