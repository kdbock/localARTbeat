import 'dart:async';

import 'package:artbeat_core/artbeat_core.dart';

class EventSubmissionCheckoutResult {
  const EventSubmissionCheckoutResult({
    required this.productId,
    required this.status,
    this.purchaseId,
    this.transactionId,
    this.amount,
    this.currency,
    this.rawPurchase,
  });

  final String productId;
  final String status;
  final String? purchaseId;
  final String? transactionId;
  final double? amount;
  final String? currency;
  final CompletedPurchase? rawPurchase;
}

class EventSubmissionCheckoutService {
  EventSubmissionCheckoutService({InAppPurchaseManager? purchaseManager})
    : _purchaseManager = purchaseManager ?? InAppPurchaseManager();

  static const String productId = 'artbeat_event_submission_review';
  static const Duration _purchaseTimeout = Duration(minutes: 3);

  final InAppPurchaseManager _purchaseManager;

  Future<EventSubmissionCheckoutResult> purchaseSubmissionReview({
    required String eventTitle,
    required String contactEmail,
  }) async {
    final checkoutId = 'event_${DateTime.now().millisecondsSinceEpoch}';

    if (!_purchaseManager.isInitialized) {
      final initialized = await _purchaseManager.initialize();
      if (!initialized) {
        throw Exception('In-app purchases are not available right now.');
      }
    }

    final completion = _waitForPurchase(checkoutId);
    final started = await _purchaseManager.purchaseProduct(
      productId,
      metadata: <String, dynamic>{
        'checkoutId': checkoutId,
        'module': 'events',
        'productFamily': 'event_submission',
        'eventTitle': eventTitle.trim(),
        'contactEmail': contactEmail.trim(),
      },
    );

    if (!started) {
      throw Exception('The store did not start the event submission purchase.');
    }

    final purchase = await completion;
    return EventSubmissionCheckoutResult(
      productId: productId,
      status: purchase.status,
      purchaseId: purchase.purchaseId,
      transactionId: purchase.transactionId,
      amount: purchase.amount,
      currency: purchase.currency,
      rawPurchase: purchase,
    );
  }

  Future<CompletedPurchase> _waitForPurchase(String checkoutId) {
    late final StreamSubscription<PurchaseEvent> subscription;
    final completer = Completer<CompletedPurchase>();

    subscription = _purchaseManager.purchaseEventStream.listen((event) {
      if (event.type == PurchaseEventType.error && !completer.isCompleted) {
        completer.completeError(
          Exception(event.error ?? 'Event submission purchase failed.'),
        );
        return;
      }

      if (event.type == PurchaseEventType.cancelled &&
          event.productId == productId &&
          !completer.isCompleted) {
        completer.completeError(Exception('Event submission purchase cancelled.'));
        return;
      }

      final purchase = event.purchase;
      if (event.type == PurchaseEventType.completed &&
          purchase != null &&
          purchase.productId == productId &&
          purchase.metadata['checkoutId'] == checkoutId &&
          !completer.isCompleted) {
        completer.complete(purchase);
      }
    });

    return completer.future
        .timeout(
          _purchaseTimeout,
          onTimeout: () => throw TimeoutException(
            'Timed out waiting for event submission purchase confirmation.',
            _purchaseTimeout,
          ),
        )
        .whenComplete(subscription.cancel);
  }
}
