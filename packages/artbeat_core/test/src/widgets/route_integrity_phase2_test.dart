import 'package:artbeat_core/src/routing/app_routes.dart';
import 'package:artbeat_core/src/widgets/artbeat_drawer_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 2 route integrity', () {
    test('core drawer routes align with AppRoutes constants', () {
      expect(ArtbeatDrawerItems.dashboard.route, AppRoutes.dashboard);
      expect(ArtbeatDrawerItems.browse.route, AppRoutes.browse);
      expect(ArtbeatDrawerItems.community.route, AppRoutes.communityFeed);
      expect(ArtbeatDrawerItems.events.route, AppRoutes.eventsDiscover);
      expect(ArtbeatDrawerItems.artWalk.route, AppRoutes.artWalkDashboard);
      expect(ArtbeatDrawerItems.messaging.route, AppRoutes.messaging);
      expect(ArtbeatDrawerItems.settings.route, AppRoutes.settings);
      expect(ArtbeatDrawerItems.help.route, AppRoutes.support);
      expect(ArtbeatDrawerItems.signOut.route, AppRoutes.login);
    });

    test('artist critical routes align with AppRoutes constants', () {
      expect(ArtbeatDrawerItems.artistDashboard.route, AppRoutes.artistDashboard);
      expect(ArtbeatDrawerItems.uploadArtwork.route, AppRoutes.artworkUpload);
      expect(ArtbeatDrawerItems.artistAnalytics.route, AppRoutes.artistAnalytics);
      expect(ArtbeatDrawerItems.artistPublicProfile.route, AppRoutes.artistPublicProfile);
      expect(ArtbeatDrawerItems.artistBrowse.route, AppRoutes.artistBrowse);
      expect(ArtbeatDrawerItems.featuredArtists.route, AppRoutes.artistFeatured);
      expect(ArtbeatDrawerItems.payoutRequest.route, AppRoutes.artistPayoutRequest);
      expect(ArtbeatDrawerItems.payoutAccounts.route, AppRoutes.artistPayoutAccounts);
    });

    test('admin and moderation routes align with AppRoutes constants', () {
      expect(ArtbeatDrawerItems.unifiedAdminDashboard.route, AppRoutes.adminDashboard);
      expect(ArtbeatDrawerItems.adminSettings.route, AppRoutes.adminSettings);
      expect(ArtbeatDrawerItems.moderatorDashboard.route, AppRoutes.adminDashboard);
      expect(ArtbeatDrawerItems.captureModeration.route, AppRoutes.captureAdminModeration);
      expect(ArtbeatDrawerItems.artWalkModeration.route, AppRoutes.artWalkAdminModeration);
    });
  });
}
