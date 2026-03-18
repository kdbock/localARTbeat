kristy manual QA notes
======================

Date: 2026-02-27

Progress:
- User A created successfully.
- Data rights requests submitted successfully.

Blocking issue:
- Deletion request could not be fulfilled from admin queue.
- UI error shown: `[firebase_functions/internal] INTERNAL`.
- Screenshot captured (admin data rights screen + red error panel).

Status:
- Manual QA session currently `FAIL` (blocked at deletion fulfillment).
- Keep canary sign-off open until deletion fulfillment succeeds.

kristykelly@Kristys-MBP artbeat % flutter run
Launching lib/main.dart on iPhone 17 Pro Max in debug mode...
Running Xcode build...                                                  
Xcode build done.                                           42.7s
Target native_assets required define SdkRoot but it was not provided
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Localization initialized\^[[0m
flutter: 🛡️ ========================================
flutter: 🛡️ STARTING FIREBASE CORE INIT
flutter: 🛡️ ========================================
flutter: 🛡️ Initializing Firebase Core (attempt 1, 8s timeout)...
flutter: 🛡️ Retrying Firebase Core init (attempt 2, 20s timeout)...
flutter: 🛡️ ✅ Firebase Core is available after retry
Syncing files to device iPhone 17 Pro Max...                       250ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on iPhone 17 Pro Max is available at: http://127.0.0.1:64786/_Ak0ibp9HEQ=/
The Flutter DevTools debugger and profiler on iPhone 17 Pro Max is available at:
http://127.0.0.1:64786/_Ak0ibp9HEQ=/devtools/?uri=ws://127.0.0.1:64786/_Ak0ibp9HEQ=/ws
flutter: 🛡️ About to call configureAppCheck...
flutter: 🛡️ ============================================
flutter: 🛡️ SKIPPING APP CHECK IN DEBUG MODE (TEMPORARY FIX)
flutter: 🛡️ ============================================
flutter: 🛡️ ✅ configureAppCheck completed successfully
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Start\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Init state\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Build\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Init Localization Delegate\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Init provider\^[[0m
flutter: 🧭 MyApp.build() entered
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Load Localization Delegate\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Load asset from assets/translations\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Build\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Init Localization Delegate\^[[0m
flutter: \^[[90m[🌎 Easy Localization] [DEBUG] Init provider\^[[0m
flutter: 🧭 MyApp.build() entered
flutter: 🧭 SplashScreen.build() entered
flutter: 🧭 SplashScreen.build() entered
flutter: 🧭 Splash _performNavigation() start
flutter: 🔍 UserSyncHelper: Checking user document for ARFuyX0C44PbYlHSUSlQx55b9vt2
flutter: 🧭 Splash _performNavigation() start
flutter: 🔍 DashboardViewModel: initialize() called, _isInitializing=false, _isInitialized=false
flutter: 🔍 DashboardViewModel: Starting initialization...
flutter: ⏳ UserSyncHelper: Already checking user document for ARFuyX0C44PbYlHSUSlQx55b9vt2
flutter: 🧭 SplashScreen.build() entered
flutter: 🔍 DashboardViewModel: initialize() called, _isInitializing=true, _isInitialized=false
flutter: 🔍 DashboardViewModel: Already initialized or initializing, skipping...
flutter: 🎯 [DEBUG] getPublicArtNearLocation: lat=37.785834, lng=-122.406417, radiusKm=10.0
flutter: 🎯 [DEBUG] Found 0 art clusters
flutter: ✅ Location loaded successfully: 37.785834, -122.406417
flutter: PresenceService: Updated artist profile 6eV5vsIt1czvNr25kVHH online status to true
flutter: PresenceService Debug: Total online users: 52
flutter: PresenceService Debug: Total online artists: 5
flutter: 🔍 DashboardViewModel: Initialized with critical data
flutter: 🚀 CaptureService.getAllCaptures() fetching from Firestore with limit: 50
flutter: 🎯 DashboardViewModel: Loading today's challenge
flutter: 🎯 DashboardViewModel: Loaded challenge: Art Hunter
flutter: 🔍 DashboardViewModel: Starting to load activities
flutter: 🔍 DashboardViewModel: User logged in: ARFuyX0C44PbYlHSUSlQx55b9vt2
flutter: 🔍 DashboardViewModel: Loading nearby activities
flutter: 🔍 DashboardViewModel: ✅ Background data loading started
flutter: 🔍 DashboardViewModel: _isInitializing set to false
flutter: ✅ CaptureService.getAllCaptures() found 49 captures
flutter: 🔍 DashboardViewModel: Loaded 1 nearby activities
flutter: 🔍 DashboardViewModel: Final activities count: 1
flutter: 🔍 DashboardViewModel: Finished loading activities, total: 1
flutter: 📱 DEBUG: Retrieved 10 posts from Firestore
flutter: 📱 Post 0: "" with 1 images
flutter: 📱   First image URL: https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/post_images%2FHH6BxxAdSnN1k6n2AtvCe01h8Di2%2Fpost_1769260580281_0.jpg?alt=media&token=e6e3c3b8-2a21-4930-9588-8f37ce42ee4f
flutter: 📱 Post 1: "What AI said about an update: This is a bold decision - they're prioritizing quality over speed despite the live app having retention issues. But if they're committed to this, let's make sure the plan reflects building something truly excellent." with 0 images
flutter: 📱 Post 2: "bored at work." with 1 images
flutter: 📱   First image URL: https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/post_images%2Fw0q5JAfGoPQuPGfgniIwpVbEkGG2%2Fpost_1767896626769_0.jpg?alt=media&token=fdf2b50f-9338-4b41-8949-4eb488445a54
flutter: 📱 Post 3: "Shared from ARTbeat Community

"vide 2"

Originally posted by Apple User" with 0 images
flutter: 📱 Post 4: "vide 2" with 0 images
flutter: 📱 Post 5: "video test" with 0 images
flutter: 📱 Post 6: "video test" with 0 images
flutter: 📱 Post 7: "video test" with 0 images
flutter: 📱 Post 8: "video test" with 0 images
flutter: 📱 Post 9: "ride" with 1 images
flutter: 📱   First image URL: https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/post_images%2FFLtGHRFLcrNgvObukkX3dwpyVn73%2Fpost_1766977233730_0.jpg?alt=media&token=3f974617-7887-4f5c-87c1-3c82c2b22ac1
flutter: PresenceService: Updated artist profile 6eV5vsIt1czvNr25kVHH online status to true
flutter: PresenceService: Updated artist profile 6eV5vsIt1czvNr25kVHH online status to true
flutter: PresenceService: Updated artist profile 6eV5vsIt1czvNr25kVHH online status to true
flutter: \^[[34m[🌎 Easy Localization] [WARNING] Localization key [auth_google_signin_failed] not found\^[[0m
flutter: ❌ Failed to create user document in Firestore: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
flutter: 🔍 DashboardViewModel: initialize() called, _isInitializing=false, _isInitialized=true
flutter: 🔍 DashboardViewModel: Already initialized or initializing, skipping...
flutter: PresenceService Debug: No artist profile found for llXkiV3FuPVtPXv68GWmLFNm9qb2
flutter: 🔍 DashboardViewModel: initialize() called, _isInitializing=false, _isInitialized=true
flutter: 🔍 DashboardViewModel: Already initialized or initializing, skipping...
flutter: \^[[34m[🌎 Easy Localization] [WARNING] Localization key [drawer_guest_user] not found\^[[0m
flutter: \^[[34m[🌎 Easy Localization] [WARNING] Localization key [drawer_not_signed_in] not found\^[[0m
flutter: ChatService.getTotalUnreadCount: Processing 0 chats
flutter: ChatService.getTotalUnreadCount: Processing 0 chats
flutter: ChatService.getTotalUnreadCount: Total unread count = 0
flutter: ChatService.getTotalUnreadCount: Total unread count = 0
