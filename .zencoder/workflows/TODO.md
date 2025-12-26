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

explore_dashboard_screen - 

enhanced_capture_dashboard_screen 
discover_dashboard_screen 


Screens that need redone because they no longer fit the flow:
Packages:
Ads
Admin
Art_Walk
Artwork
Artists
Auth - Done
Capture - Done except drawer items
Community
Core
Events
Messaging
Profile - Done
Settings - Done


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
