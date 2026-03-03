import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/src/models/offline_queue_item.dart';

void main() {
  group('OfflineQueueItem', () {
    CaptureModel _capture() => CaptureModel(
      id: 'c1',
      userId: 'u1',
      imageUrl: 'https://example.com/c.jpg',
      createdAt: DateTime.now(),
      title: 'Test',
    );

    test('status extension maps known and unknown strings', () {
      expect(
        OfflineQueueStatusExtension.fromString('OfflineQueueStatus.synced'),
        OfflineQueueStatus.synced,
      );
      expect(
        OfflineQueueStatusExtension.fromString('unexpected'),
        OfflineQueueStatus.pending,
      );
    });

    test('canSync and shouldAutoRetry follow retry policy', () {
      final now = DateTime.now();
      final failedRetryable = OfflineQueueItem(
        id: 'q1',
        localCaptureId: 'lc1',
        captureData: _capture(),
        localImagePath: '/tmp/x.jpg',
        status: OfflineQueueStatus.failed,
        retryCount: 2,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 6)),
      );
      final failedExhausted = failedRetryable.copyWith(retryCount: 3);

      expect(failedRetryable.canSync, isTrue);
      expect(failedRetryable.shouldAutoRetry, isTrue);
      expect(failedExhausted.canSync, isFalse);
      expect(failedExhausted.shouldAutoRetry, isFalse);
    });

    test('toJson/fromJson round-trip preserves key fields', () {
      final item = OfflineQueueItem(
        id: 'q2',
        localCaptureId: 'lc2',
        remoteCaptureId: 'rc2',
        captureData: _capture(),
        localImagePath: '/tmp/y.jpg',
        status: OfflineQueueStatus.syncing,
        retryCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastError: 'network',
        metadata: const {'source': 'test'},
      );

      final roundTrip = OfflineQueueItem.fromJson(item.toJson());
      expect(roundTrip.id, 'q2');
      expect(roundTrip.remoteCaptureId, 'rc2');
      expect(roundTrip.status, OfflineQueueStatus.syncing);
      expect(roundTrip.retryCount, 1);
      expect(roundTrip.metadata?['source'], 'test');
    });
  });
}
