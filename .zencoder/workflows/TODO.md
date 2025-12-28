refactor files to match Local ARTbeat design_guide.md

design_guide.md: /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md

Translation files: assets/translations/\*.json

Screens: /lib/src/screens/

Widgets: /lib/src/widgets/

Refactoring Tasks
// Refactor the widget/screen to match Local ARTbeat design_guide.md:
// - WorldBackground + GlassCard layout
// - Typography with GoogleFonts.spaceGrotesk
// - GradientCTAButton for main actions
// - tr() localization for all text
// - Touch targets ≥ 44px, spacing multiple of 8
// - Replace Material defaults with shared UI components
design_guide.md /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md

Add new widgets if needed from design_guide.md

Packages:
Art_Walk screens
[x] 'admin_art_walk_moderation_screen.dart';
[x] 'discover_dashboard_screen.dart';
[x] 'art_walk_detail_screen.dart'; // localized stats + marker text
[x] 'art_walk_edit_screen.dart';
[x] 'art_walk_list_screen.dart';
[x] 'art_walk_map_screen.dart';
[x] 'art_walk_review_screen.dart';
[x] 'enhanced_art_walk_create_screen.dart';
[x] 'enhanced_art_walk_experience_screen.dart';
[x] 'search_results_screen.dart';
[x] 'art_walk_celebration_screen.dart';
[x] 'enhanced_my_art_walks_screen.dart';
[x] 'instant_discovery_radar_screen.dart';
[x] 'quest_history_screen.dart';
[x] 'weekly_goals_screen.dart';
Art_walk wigdgets to redo
[x] 'achievement_badge.dart';
[x] 'achievements_grid.dart';
[x] 'art_detail_bottom_sheet.dart';
[x] 'art_walk_card.dart';
[x] 'art_walk_drawer.dart';
[x] 'art_walk_comment_section.dart';
[x] 'art_walk_header.dart';
[x] 'art_walk_info_card.dart';
[x] 'art_walk_search_filter.dart';
[x] 'enhanced_progress_visualization.dart';
[x] 'local_art_walk_preview_widget.dart';
[x] 'map_floating_menu.dart';
[x] 'new_achievement_dialog.dart';
[x] 'offline_art_walk_widget.dart';
[x] 'offline_map_fallback.dart';
[x] 'public_art_search_filter.dart';
[x] 'turn_by_turn_navigation_widget.dart';
[x] 'zip_code_search_box.dart';
[x] 'progress_cards.dart';
[x] 'instant_discovery_radar.dart';
[x] 'discovery_capture_modal.dart';
[x] 'daily_quest_card.dart';
[x] 'social_activity_feed.dart';
[x] 'weekly_goals_card.dart';
