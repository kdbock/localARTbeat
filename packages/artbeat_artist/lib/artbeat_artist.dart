/// ARTbeat Artist package with artist and gallery functionality
library;

// Models
export 'src/models/artist_profile_model.dart'
    hide ArtistProfileModel; // Hide to avoid conflict with core
export 'src/models/gallery_invitation_model.dart';
export 'src/models/subscription_model.dart';
export 'src/models/earnings_model.dart';
export 'src/models/payout_model.dart';

// Screens
export 'src/screens/visibility_insights_screen.dart';
export 'src/screens/artist_approved_ads_screen.dart';
export 'src/screens/artist_browse_screen.dart';
export 'src/screens/gallery_hub_screen.dart';
export 'src/screens/auction_hub_screen.dart';
export 'src/screens/artist_profile_edit_screen.dart';
export 'src/screens/artist_public_profile_screen.dart';
// import removed: use artwork_browse_screen from artbeat_artwork package instead
export 'src/screens/event_creation_screen.dart';
export 'src/screens/events_screen.dart';
export 'src/screens/gallery_visibility_hub_screen.dart';
export 'src/screens/gallery_artists_management_screen.dart';
export 'src/screens/artist_onboard_screen.dart';
export 'src/screens/my_artwork_screen.dart';
export 'src/screens/payment_methods_screen.dart';
export 'src/screens/payment_screen.dart';
export 'src/screens/refund_request_screen.dart';
export 'src/screens/subscription_analytics_screen.dart';
export 'src/screens/verified_artist_screen.dart';
export 'src/screens/featured_artist_screen.dart';
export 'src/screens/artist_journey_screen.dart';

// Earnings screens
export 'src/screens/earnings/artist_earnings_hub.dart';
export 'src/screens/earnings/artwork_sales_hub.dart';
export 'src/screens/earnings/payout_request_screen.dart';
export 'src/screens/earnings/payout_accounts_screen.dart';

// Services
export 'src/services/visibility_service.dart';
export 'src/services/artist_profile_service.dart';
export 'src/services/subscription_service.dart';
export 'src/services/gallery_invitation_service.dart';
export 'src/services/event_service_adapter.dart';
export 'src/services/earnings_service.dart';
export 'src/services/integration_service.dart'; // NEW: Cross-package integration

// Phase 1 Enhanced Services
export 'src/services/navigation_service.dart';
export 'src/services/community_service.dart';
export 'src/services/offline_data_provider.dart';
export 'src/services/filter_service.dart';
export 'src/services/subscription_validation_service.dart';
export 'src/services/subscription_plan_validator.dart';

// Deprecated Services (for migration)
export 'src/services/artist_service.dart';
export 'src/services/artwork_service.dart';

// Widgets
export 'src/widgets/widgets.dart';
