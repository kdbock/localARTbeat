import 'package:artbeat_artwork/src/services/artwork_pagination_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginationState', () {
    test('copyWith overrides selected fields', () {
      final state = PaginationState(
        items: const [],
        hasMore: true,
        isLoading: true,
      );

      final updated = state.copyWith(
        hasMore: false,
        isLoading: false,
        error: 'failed',
      );

      expect(updated.items, isEmpty);
      expect(updated.hasMore, isFalse);
      expect(updated.isLoading, isFalse);
      expect(updated.error, 'failed');
    });
  });
}
