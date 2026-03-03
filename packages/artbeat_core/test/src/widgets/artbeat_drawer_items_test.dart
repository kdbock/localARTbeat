import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/src/widgets/artbeat_drawer_items.dart';

void main() {
  group('ArtbeatDrawerItems role filtering', () {
    test(
      'guest gets navigation/personal/settings but no role-restricted artist items',
      () {
        final guestSections = ArtbeatDrawerItems.getSectionsForRole(null);
        final guestRoutes = guestSections
            .expand((section) => section.items)
            .map((item) => item.route)
            .toSet();

        expect(guestRoutes.contains('/dashboard'), isTrue);
        expect(guestRoutes.contains('/browse'), isTrue);
        expect(guestRoutes.contains('/subscription/plans'), isFalse);
        expect(guestRoutes.contains('/artist/dashboard'), isFalse);
      },
    );

    test('artist gets artist management routes', () {
      final artistSections = ArtbeatDrawerItems.getSectionsForRole('artist');
      final artistRoutes = artistSections
          .expand((section) => section.items)
          .map((item) => item.route)
          .toSet();

      expect(artistRoutes.contains('/artist/dashboard'), isTrue);
      expect(artistRoutes.contains('/artist/analytics'), isTrue);
      expect(artistRoutes.contains('/artist/payout-request'), isTrue);
      expect(artistRoutes.contains('/subscription/plans'), isTrue);
      expect(artistRoutes.contains('/admin/dashboard'), isFalse);
    });

    test('admin gets admin routes and not artist-only payout routes', () {
      final adminSections = ArtbeatDrawerItems.getSectionsForRole('admin');
      final adminRoutes = adminSections
          .expand((section) => section.items)
          .map((item) => item.route)
          .toSet();

      expect(adminRoutes.contains('/admin/dashboard'), isTrue);
      expect(adminRoutes.contains('/admin/settings'), isTrue);
      expect(adminRoutes.contains('/admin/monitoring'), isTrue);
      expect(adminRoutes.contains('/artist/payout-request'), isFalse);
    });
  });
}
