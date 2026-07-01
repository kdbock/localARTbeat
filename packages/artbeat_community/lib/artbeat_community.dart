/// ARTbeat Community package with social and community functionality
library artbeat_community;

// Export all screens via the barrel file
export 'screens/screens.dart';

// Models
export 'models/models.dart';
export 'models/post_model.dart';
export 'models/comment_model.dart';
export 'models/artwork_model.dart';

export 'models/group_models.dart' show GroupType;

// NEW SIMPLIFIED EXPORTS
export 'models/art_models.dart';
export 'services/art_community_service.dart';
export 'services/firebase_storage_service.dart';
export 'screens/art_community_hub.dart';

// Services
export 'services/services.dart';
export 'services/community_service.dart';
export 'services/storage_service.dart';
export 'services/moderation_service.dart';

// Widgets
export 'widgets/widgets.dart';
export 'widgets/post_card.dart';
export 'widgets/feedback_thread_widget.dart';
export 'widgets/applause_button.dart';
export 'widgets/avatar_widget.dart';
export 'widgets/artwork_card_widget.dart';
export 'widgets/group_post_card.dart';
export 'widgets/community_drawer.dart';
export 'src/widgets/report_dialog.dart';
export 'src/widgets/user_action_menu.dart';

// Controllers
export 'controllers/controllers.dart';
