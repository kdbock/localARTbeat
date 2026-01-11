/// ARTbeat Community package with social and community functionality
library artbeat_community;

// Export all screens via the barrel file
export 'screens/screens.dart';

// Models
export 'models/models.dart';
export 'models/post_model.dart';
export 'models/comment_model.dart';
export 'models/artwork_model.dart';
export 'models/studio_model.dart';
export 'models/gift_model_export.dart'; // Use export file to avoid conflicts
export 'models/direct_commission_model.dart';
export 'models/art_battle_match.dart';

export 'models/group_models.dart' show GroupType;

// NEW SIMPLIFIED EXPORTS
export 'models/art_models.dart';
export 'services/art_community_service.dart';
export 'services/firebase_storage_service.dart';
export 'widgets/art_gallery_widgets.dart';
export 'screens/art_community_hub.dart';
export 'screens/create_art_post_screen.dart';
export 'screens/art_battle_screen.dart';

// Services
export 'services/services.dart';
export 'services/community_service.dart';
export 'services/storage_service.dart';
export 'services/direct_commission_service.dart';
export 'services/stripe_service.dart';
export 'services/moderation_service.dart';
export 'services/art_battle_service.dart';

// Widgets
export 'widgets/widgets.dart';
export 'widgets/post_card.dart';
export 'widgets/feedback_thread_widget.dart';
export 'widgets/applause_button.dart';
export 'widgets/avatar_widget.dart';
export 'widgets/artwork_card_widget.dart';
export 'widgets/gift_card_widget.dart';
export 'widgets/group_feed_widget.dart';
export 'widgets/group_post_card.dart';
export 'widgets/create_post_fab.dart';
export 'widgets/artist_list_widget.dart';
export 'widgets/community_drawer.dart';
export 'widgets/commission_artists_browser.dart';
export 'widgets/commission_filter_dialog.dart';
export 'src/widgets/report_dialog.dart';
export 'src/widgets/user_action_menu.dart';

// Controllers
export 'controllers/controllers.dart';
