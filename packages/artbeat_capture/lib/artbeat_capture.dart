library artbeat_capture;

// Re-export the model from core
export 'package:artbeat_core/artbeat_core.dart' show CaptureModel;

// Screens and services
export 'src/screens/enhanced_capture_dashboard_screen.dart';
export 'src/screens/captures_list_screen.dart';
export 'src/screens/terms_and_conditions_screen.dart';
export 'src/screens/capture_upload_screen.dart';
export 'src/screens/capture_detail_screen.dart';
export 'src/screens/capture_detail_viewer_screen.dart';
export 'src/screens/capture_edit_screen.dart';
export 'src/screens/admin_content_moderation_screen.dart';
export 'src/screens/my_captures_screen.dart';
export 'src/screens/capture_screen.dart';
export 'src/screens/capture_view_screen.dart';
export 'src/services/capture_service.dart';
export 'src/services/storage_service.dart';
export 'src/services/camera_service.dart';
export 'src/services/advanced_camera_service.dart';
export 'src/services/ai_ml_integration_service.dart';
export 'src/services/capture_analytics_service.dart';
export 'src/services/capture_terms_service.dart';

// Deprecated: Use core.SearchResultsPage instead
// export 'src/screens/capture_search_screen.dart';

// Widgets
export 'src/widgets/captures_grid.dart';
export 'src/widgets/artist_search_dialog.dart';
export 'src/widgets/map_picker_dialog.dart';
export 'src/widgets/capture_drawer.dart';
export 'src/widgets/like_button_widget.dart';
export 'src/widgets/comment_item_widget.dart';
export 'src/widgets/comments_section_widget.dart';

// New widgets
export 'src/widgets/glass_card.dart';
export 'src/widgets/hud_top_bar.dart';
export 'src/widgets/hud_button.dart';
export 'src/widgets/xp_bar.dart';
export 'src/widgets/mini_stat_card.dart';
export 'src/widgets/quest_capture_tile.dart';
export 'src/widgets/quest_community_card.dart';
export 'src/widgets/section_header.dart';
export 'src/widgets/quick_action_chip.dart';
export 'src/widgets/mission_card.dart';
export 'src/widgets/drawer_section_header.dart';
export 'src/widgets/drawer_item_pill.dart';
export 'src/widgets/glass_input_decoration.dart';
export 'src/widgets/glass_text_field.dart';

// Models and Utils
export 'src/models/media_capture.dart';
export 'src/models/offline_queue_item.dart';
export 'src/utils/capture_helper.dart';
