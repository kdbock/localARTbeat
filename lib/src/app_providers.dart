import 'package:provider/single_child_widget.dart';

import 'providers/art_walk_events_capture_providers.dart';
import 'providers/community_providers.dart';
import 'providers/core_foundation_providers.dart';
import 'providers/profile_artwork_providers.dart';
import 'providers/sponsorship_providers.dart';

List<SingleChildWidget> createAppProviders() => [
  ...createCoreFoundationProviders(),
  ...createCommunityProviders(),
  ...createProfileArtworkProviders(),
  ...createArtWalkEventsCaptureProviders(),
  ...createSponsorshipProviders(),
];
