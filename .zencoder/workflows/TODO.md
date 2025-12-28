File Reference Shortcuts

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

Screens with the new design:

login_screen
registration_screen
Forgot_password_screen
splash_screen
animated_dashbaord_screen
explore_dashboard_screen -
enhanced_capture_dashboard_screen
discover_dashboard_screen
events_list_screen
event_details_screen

Next screen target: events_dashboard_screen

Screens that need redone because they no longer fit the flow:
Packages:
Ads
Admin
Art_Walk screens
[ ] 'admin_art_walk_moderation_screen.dart';
[ ] 'discover_dashboard_screen.dart';
[ ] 'art_walk_detail_screen.dart';
[ ] 'art_walk_edit_screen.dart';
[ ] 'art_walk_list_screen.dart';
[ ] 'art_walk_map_screen.dart';
[ ] 'art_walk_review_screen.dart';
[ ] 'enhanced_art_walk_create_screen.dart';
[ ] 'enhanced_art_walk_experience_screen.dart';
[ ] 'search_results_screen.dart';
[ ] 'art_walk_celebration_screen.dart';
[ ] 'enhanced_my_art_walks_screen.dart';
[ ] 'instant_discovery_radar_screen.dart';
[ ] 'quest_history_screen.dart';
[ ] 'weekly_goals_screen.dart';
Art_walk wigdgets to redo
[ ] 'achievement_badge.dart';
[ ] 'achievements_grid.dart';
[ ] 'art_detail_bottom_sheet.dart';
[ ] 'art_walk_card.dart';
[ ] 'art_walk_drawer.dart';
[ ] 'art_walk_comment_section.dart';
[ ] 'art_walk_header.dart';
[ ] 'art_walk_info_card.dart';
[ ] 'art_walk_search_filter.dart';
[ ] 'enhanced_progress_visualization.dart';
[ ] 'local_art_walk_preview_widget.dart';
[ ] 'map_floating_menu.dart';
[ ] 'new_achievement_dialog.dart';
[ ] 'offline_art_walk_widget.dart';
[ ] 'offline_map_fallback.dart';
[ ] 'public_art_search_filter.dart';
[ ] 'turn_by_turn_navigation_widget.dart';
[ ] 'zip_code_search_box.dart';
[ ] 'progress_cards.dart';
[ ] 'instant_discovery_radar.dart';
[ ] 'discovery_capture_modal.dart';
[ ] 'daily_quest_card.dart';
[ ] 'social_activity_feed.dart';
[ ] 'weekly_goals_card.dart';

Artwork
Artists
Auth - Done
Capture - Done
Community
Core - Done
Events - Done
Messaging

Profile - Done
Settings - Done

checklist for visual updates and language localization and translations
create unused screens/widgets checklist for removal after review removed unused screens
add missing translations to en.json, es.json, de.json, fr.json, pt.json, ar.json, and zh.json
update translations in strings.dart file (no strings.dart file found, translations are in json files)
remove unused translations from strings.dart file (no strings.dart file)
ensure all translated text is wrapped in tr() key calls
confirm all translated text has been added to the appropriate json files
confirm all translated text has been removed from the strings.dart file if it was previously used but no longer needed (no strings.dart file)
identify unused screens/widgets
review _all_ files in artbeat_profile package for unused screens/widgets
audit each screen/widget for visual consistency with new design

🎨 Visual Design Update Checklist (artbeat_profile package): overhaul visual appearance while refactoring some screens to fit the new asthetics.
design_guide.md /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md

Check for localization key usage in each screen/widget and add missing translations to en.json, es.json, de.json, fr.json, pt.json, ar.json, and zh.json

Then go package by package updating screens and widgets to reflect the new visual design

Workflow Plan

Audit & Prioritize – Inventory existing screens, flag outdated Explore/Discover/Capture dashboards, confirm routing/tap targets, log any TODO/Coming Soon remnants
Design Alignment – Gather new visual specs, define shared theming/components, create UI references for the three priority dashboards before implementation
Implement Dashboards – Update explore_dashboard_screen, discover_dashboard_screen, enhanced_capture_dashboard_screen sequentially: restructure layout, navigation hooks, data bindings, and interaction flows per new goals
Validation Pass – Ensure each updated screen is registered in navigators, list items navigate with required params, and new interactions are tested on-device
Next Screens – Tackle events_dashboard_screen, then audit all artbeat_profile screens/widgets for consistency; fix routing, visuals, and TODOs as discovered
Package Rollout – Move package by package updating screens/widgets to the new styles, verifying there are no redundant/orphan screens and that tap-to-navigate is universal
Regression & QA – Run flutter analyzer/tests, perform UX sweeps, and capture any remaining polish tasks before release
