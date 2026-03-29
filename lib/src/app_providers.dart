import 'package:provider/single_child_widget.dart';

import 'providers/admin_sponsorship_providers.dart';
import 'providers/art_walk_events_capture_providers.dart';
import 'providers/artist_monetization_providers.dart';
import 'providers/community_messaging_providers.dart';
import 'providers/core_foundation_providers.dart';
import 'providers/profile_artwork_providers.dart';

List<SingleChildWidget> createAppProviders() => [
  ...createCoreFoundationProviders(),
  ...createCommunityMessagingProviders(),
  ...createProfileArtworkProviders(),
  ...createArtWalkEventsCaptureProviders(),
  ...createArtistMonetizationProviders(),
  ...createAdminSponsorshipProviders(),
];
