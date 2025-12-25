Current State:

Local ARTbeat app is live on Google and Apple.

We are overhauling visual appearance while refactoring some screens to fit the new asthetics.
design_guide.md /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md
Screens with the new design:

login_screen

registration_screen

Forgot_password_screen

splash_screen

animated_dashbaord_screen

explore_dashboard_screen - complete & routed (packages/artbeat_core/lib/src/screens/dashboard/explore_dashboard_screen.dart)

enhanced_capture_dashboard_screen - complete & routed (packages/artbeat_capture/lib/src/screens/enhanced_capture_dashboard_screen.dart)

discover_dashboard_screen - hero now stops at the hamburger/menu + greeting row so the Instant Discovery radar sits directly beneath; XP/tags/mission/CTAs live in a glass details section after the radar to keep the CTA primary (packages/artbeat_art_walk/lib/src/screens/discover_dashboard_screen.dart)
Translations for this screen remain updated across assets/translations/{en,es,de,fr,pt,ar,zh}.json

Screens that need redone because they no longer fit the flow:

- Pending next audit pass

Currently working on:

artbeat_profile package screens and widgets
first steps - check routing ✅
create check list of active screens in artbeat_profile screens and widgets

Active Screens (routed in app_router.dart or used elsewhere):

- EditProfileScreen ✅
- ProfileViewScreen ✅
- ProfilePictureViewerScreen ✅
- ProfileConnectionsScreen ✅
- ProfileAnalyticsScreen ✅
- AchievementsScreen ✅
- FollowedArtistsScreen ✅
- FollowersListScreen ✅
- FavoritesScreen ✅
- AchievementInfoScreen ✅
- CreateProfileScreen (used in auth) ✅
- ProfileTab (used in advanced_analytics_dashboard) ✅

Potentially Unused Screens (not found in routing or usage search):

- DiscoverScreen ✅ removed
- ProfileCustomizationScreen ✅ removed
- ProfileMentionsScreen ✅ removed
- ProfileHistoryScreen ✅ removed

Active but not in initial routing list:

- FavoriteDetailScreen (routed in core_route_handler)
- FollowingListScreen (used in bin/main.dart)
- ProfileActivityScreen (used in app_router)

Widgets:

- ProfileHeader ✅ removed (unused)
- LevelProgressBar ✅ active (used in profile_view_screen)
- StreakDisplay ✅ active (used in profile_view_screen)
- RecentBadgesCarousel ✅ active (used in profile_view_screen)
- EnhancedStatsGrid ✅ active (used in profile_view_screen)
- CelebrationModals ✅ removed (unused)
- ProgressTab ✅ active (used in profile_view_screen)
- DynamicAchievementsTab ✅ active (used in profile_view_screen)

checklist for visual updates and language localization and translations ✅
create unused screens/widgets checklist for removal after review ✅ removed unused screens
add missing translations to en.json, es.json, de.json, fr.json, pt.json, ar.json, and zh.json ✅
update translations in strings.dart file (no strings.dart file found, translations are in json files)
remove unused translations from strings.dart file (no strings.dart file)
ensure all translated text is wrapped in tr() key calls ✅
confirm all translated text has been added to the appropriate json files ✅
confirm all translated text has been removed from the strings.dart file if it was previously used but no longer needed (no strings.dart file)
identify unused screens/widgets ✅
review _all_ files in artbeat_profile package for unused screens/widgets ✅
audit each screen/widget for visual consistency with new design

🎨 Visual Design Update Checklist (artbeat_profile package): overhaul visual appearance while refactoring some screens to fit the new asthetics.
design_guide.md /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md
Screens that need the new design:

Active Screens:

- [x] EditProfileScreen - Update to new design system
- [x] ProfileViewScreen - Update to new design system
- [x] ProfilePictureViewerScreen - Update to new design system
- [x] ProfileConnectionsScreen - Update to new design system
- [x] ProfileAnalyticsScreen - Update to new design system
- [x] AchievementsScreen - Update to new design system
- [x] FollowedArtistsScreen - Update to new design system
- [x] FollowersListScreen - Update to new design system
- [x] FavoritesScreen - Update to new design system
- [ ] AchievementInfoScreen - Update to new design system
- [ ] CreateProfileScreen - Update to new design system
- [ ] ProfileTab - Update to new design system
- [ ] FavoriteDetailScreen - Update to new design system
- [ ] FollowingListScreen - Update to new design system
- [ ] ProfileActivityScreen - Update to new design system

Active Widgets:

- [ ] LevelProgressBar - Update to new design system
- [ ] StreakDisplay - Update to new design system
- [ ] RecentBadgesCarousel - Update to new design system
- [ ] EnhancedStatsGrid - Update to new design system
- [ ] ProgressTab - Update to new design system
- [ ] DynamicAchievementsTab - Update to new design system

Check for localization key usage in each screen/widget and add missing translations to en.json, es.json, de.json, fr.json, pt.json, ar.json, and zh.json


- [x] EditProfileScreen - Update to new design system
- [x] ProfileViewScreen - Update to new design system
- [ ] ProfilePictureViewerScreen - Update to new design system
- [ ] ProfileConnectionsScreen - Update to new design system
- [ ] ProfileAnalyticsScreen - Update to new design system
- [ ] AchievementsScreen - Update to new design system
- [ ] FollowedArtistsScreen - Update to new design system
- [ ] FollowersListScreen - Update to new design system
- [ ] FavoritesScreen - Update to new design system
- [ ] AchievementInfoScreen - Update to new design system
- [ ] CreateProfileScreen - Update to new design system
- [ ] ProfileTab - Update to new design system
- [ ] FavoriteDetailScreen - Update to new design system
- [ ] FollowingListScreen - Update to new design system
- [ ] ProfileActivityScreen - Update to new design system

Active Widgets:

- [ ] LevelProgressBar - Update to new design system
- [ ] StreakDisplay - Update to new design system
- [ ] RecentBadgesCarousel - Update to new design system
- [ ] EnhancedStatsGrid - Update to new design system
- [ ] ProgressTab - Update to new design system
- [ ] DynamicAchievementsTab - Update to new design system
log any routing issues, visual inconsistencies, and TODO/Coming Soon remnants
fix routing issues, visual inconsistencies, and TODO/Coming Soon remnants

Then go package by package updating screens and widgets to reflect the new visual design

Workflow Plan

Audit & Prioritize – Inventory existing screens, flag outdated Explore/Discover/Capture dashboards, confirm routing/tap targets, log any TODO/Coming Soon remnants
Design Alignment – Gather new visual specs, define shared theming/components, create UI references for the three priority dashboards before implementation
Implement Dashboards – Update explore_dashboard_screen, discover_dashboard_screen, enhanced_capture_dashboard_screen sequentially: restructure layout, navigation hooks, data bindings, and interaction flows per new goals
Validation Pass – Ensure each updated screen is registered in navigators, list items navigate with required params, and new interactions are tested on-device
Next Screens – Tackle events_dashboard_screen, then audit all artbeat_profile screens/widgets for consistency; fix routing, visuals, and TODOs as discovered
Package Rollout – Move package by package updating screens/widgets to the new styles, verifying there are no redundant/orphan screens and that tap-to-navigate is universal
Regression & QA – Run flutter analyzer/tests, perform UX sweeps, and capture any remaining polish tasks before release
