
failed 4 minutes ago in 1m 21s
Search logs
1s
4s
22s
7s
44s
Run if [ -d "test" ] && [ -n "$(find test -name '*.dart' -type f)" ]; then
00:00 +0: loading /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart
/tmp/flutter_tools.UCFGKC/flutter_test_listener.ADQTNM/listener.dart:21:21: Error: Undefined name 'main'.
  await Future(test.main);
                    ^^^^
00:00 +0 -1: loading /home/runner/work/artbeat-app/artbeat-app/test/main_dashboard_complete_test.dart [E]
  Failed to load "/home/runner/work/artbeat-app/artbeat-app/test/main_dashboard_complete_test.dart":
  Compilation failed for testPath=/home/runner/work/artbeat-app/artbeat-app/test/main_dashboard_complete_test.dart: /tmp/flutter_tools.UCFGKC/flutter_test_listener.ADQTNM/listener.dart:21:21: Error: Undefined name 'main'.
    await Future(test.main);
                      ^^^^
  .
00:00 +0 -2: loading /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart [E]
  Error: The Dart compiler exited unexpectedly.
  package:flutter_tools/src/base/common.dart 34:3  throwToolExit
  package:flutter_tools/src/compile.dart 910:11    DefaultResidentCompiler._compile.<fn>
  dart:async/zone.dart 1538:47                     _rootRunUnary
  dart:async/zone.dart 1429:19                     _CustomZone.runUnary
  dart:async/future_impl.dart 948:45               Future._propagateToListeners.handleValueCallback
  dart:async/future_impl.dart 977:13               Future._propagateToListeners
  dart:async/future_impl.dart 862:9                Future._propagateToListeners
  dart:async/future_impl.dart 720:5                Future._completeWithValue
  dart:async/future_impl.dart 804:7                Future._asyncCompleteWithValue.<fn>
  dart:async/zone.dart 1525:13                     _rootRun
  dart:async/zone.dart 1422:19                     _CustomZone.run
  dart:async/zone.dart 1321:7                      _CustomZone.runGuarded
  dart:async/zone.dart 1362:23                     _CustomZone.bindCallbackGuarded.<fn>
  dart:async/schedule_microtask.dart 40:35         _microtaskLoop
  dart:async/schedule_microtask.dart 49:5          _startMicrotaskLoop
  dart:isolate-patch/isolate_patch.dart 127:13     _runPendingImmediateCallback
  dart:isolate-patch/isolate_patch.dart 194:5      _RawReceivePort._handleMessage
  
00:00 +0 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Distance Calculations calculates distance between two points correctly
00:00 +1 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Distance Calculations calculates bearing between two points correctly
00:00 +2 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Distance Calculations calculates bearing for east direction correctly
00:00 +3 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Proximity Messages returns correct message for very close distance
00:00 +4 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Proximity Messages returns correct message for close distance
00:00 +5 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Proximity Messages returns correct message for medium distance
00:00 +6 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Proximity Messages returns correct message for far distance
00:00 +7 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Proximity Messages handles boundary conditions correctly
00:00 +8 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Geohash Generation generates geohash with correct length
00:00 +9 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Geohash Generation generates consistent geohash for same location
00:00 +10 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Geohash Generation generates different geohashes for different locations
00:00 +11 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Geohash Generation generates geohash with valid base32 characters
00:00 +12 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Geohash Generation nearby locations have similar geohash prefixes
00:00 +13 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - XP Calculations calculates base discovery XP correctly
00:00 +14 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - XP Calculations calculates first discovery of day bonus correctly
00:00 +15 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - XP Calculations calculates streak bonus correctly
00:00 +16 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - XP Calculations calculates maximum XP with all bonuses
00:00 +17 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Radar Positioning normalizes distance correctly
00:00 +18 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Radar Positioning clamps distance beyond radius
00:00 +19 -2: /home/runner/work/artbeat-app/artbeat-app/test/instant_discovery_test.dart: Instant Discovery - Radar Positioning handles zero distance correctly
00:16 +20 -2: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) (setUpAll)
Firebase initialization warning in test: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore"., null, null)
00:16 +20 -2: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch
00:16 +21 -2: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch
00:16 +22 -2: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch
00:16 +23 -2: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch
Pending timers:
Timer (duration: 0:00:00.200000, periodic: false), created:
#0      new FakeTimer._ (package:fake_async/fake_async.dart:342:62)
#1      FakeAsync._createTimer (package:fake_async/fake_async.dart:260:29)
#2      FakeAsync.run.<anonymous closure> (package:fake_async/fake_async.dart:185:15)
#6      _SplashScreenState._checkAuthAndNavigate (package:artbeat_core/src/screens/splash_screen.dart:67:11)
#7      _SplashScreenState.initState (package:artbeat_core/src/screens/splash_screen.dart:32:5)
#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#237    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#238    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#239    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#704    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#705    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#706    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#707    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#708    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#709    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#710    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#711    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#712    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#713    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#714    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#715    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#716    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#717    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#718    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#719    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#720    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#721    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#722    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#723    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#724    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#725    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#726    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#727    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#728    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#729    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#730    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#731    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#732    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#733    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#734    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#735    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#736    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#737    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#738    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#739    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#740    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#741    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#742    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#743    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#744    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#745    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#746    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#749    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#750    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#751    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#752    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#753    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#754    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#755    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#756    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#757    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#758    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#759    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#760    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#761    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#762    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#763    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#764    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#765    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#766    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#767    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#768    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#769    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#770    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#771    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#774    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#775    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#776    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#779    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#780    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#781    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:29:22)
#782    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#783    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 8 frames from dart:async and package:stack_trace)

══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
A Timer is still pending even after the widget tree was disposed.
'package:flutter_test/src/binding.dart':
Failed assertion: line 1617 pos 12: '!timersPending'

When the exception was thrown, this was the stack:
#2      AutomatedTestWidgetsFlutterBinding._verifyInvariants (package:flutter_test/src/binding.dart:1617:12)
#3      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1078:7)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from class _AssertionError and package:stack_trace)

The test description was:
  ✅ Splash screen displays on app launch
════════════════════════════════════════════════════════════════════════════════════════════════════
00:17 +23 -3: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
00:17 +23 -3: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch [E]
  Test failed. See exception logs above.
  The test description was: ✅ Splash screen displays on app launch
  
00:17 +23 -3: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Login screen displays correctly with Firebase
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:17 +23 -3: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:17 +24 -3: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
00:17 +24 -3: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Register screen displays correctly with Firebase
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
00:17 +25 -3: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
00:17 +25 -3: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Forgot Password screen displays correctly with Firebase
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
00:17 +26 -3: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
00:17 +26 -3: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Email verification screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:132:17

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      _EmailVerificationScreenState.initState (package:artbeat_auth/src/screens/email_verification_screen.dart:29:26)
#4      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#5      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#233    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#234    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#235    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#700    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#701    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#702    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#703    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#704    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#705    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#706    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#707    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#708    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#709    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#710    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#711    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#712    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#713    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#714    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#715    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#716    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#717    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#718    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#719    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#720    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#721    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#722    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#723    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#724    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#725    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#726    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#727    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#728    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#729    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#730    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#731    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#732    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#733    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#734    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#735    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#736    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#737    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#738    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#739    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#740    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#741    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#742    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#743    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#744    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#745    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#746    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#747    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#748    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#749    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#750    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#751    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#752    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#753    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#754    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#755    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#756    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#757    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#758    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#759    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#760    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#761    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#762    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#763    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#764    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#765    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#766    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#767    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#770    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#771    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#772    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#775    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#776    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#777    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:131:22)
#778    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#779    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "EmailVerificationScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:139:9)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart line 139
The test description was:
  Email verification screen displays correctly
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:17 +26 -4: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
00:17 +26 -4: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Email verification screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Email verification screen displays correctly
  
00:17 +26 -4: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Profile creation screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building ProfileCreateScreen(dirty):
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  ProfileCreateScreen
  ProfileCreateScreen:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:143:57

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      ProfileCreateScreen.build (package:artbeat_auth/src/screens/profile_create_screen.dart:15:31)
#4      StatelessElement.build (package:flutter/src/widgets/framework.dart:5791:49)
#5      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#6      Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#7      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:5705:5)
#8      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#236    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#237    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#238    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#703    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#704    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#705    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#706    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#707    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#708    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#709    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#710    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#711    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#712    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#713    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#714    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#715    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#716    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#717    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#718    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#719    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#720    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#721    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#722    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#723    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#724    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#725    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#726    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#727    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#728    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#729    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#730    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#731    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#732    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#733    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#734    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#735    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#736    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#737    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#738    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#739    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#740    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#741    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#742    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#743    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#744    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#745    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#746    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#747    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#748    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#749    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#750    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#751    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#752    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#753    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#754    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#755    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#756    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#757    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#758    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#759    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#760    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#761    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#762    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#763    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#764    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#765    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#766    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#767    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#768    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#769    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#770    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#773    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#774    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#775    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#778    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#779    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#780    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:143:22)
#781    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#782    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:17 +26 -5: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation LoginScreen should be ready for social login buttons
00:17 +26 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Profile creation screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Profile creation screen displays correctly
  
00:17 +26 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Interaction Tests with Firebase Login form accepts text input
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:17 +27 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Interaction Tests with Firebase Login form accepts text input
00:17 +27 -5: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation should have Google Sign-In button integrated
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:18 +28 -5: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation should have Google Sign-In button integrated
00:18 +29 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Interaction Tests with Firebase Registration form accepts text input
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
00:18 +29 -5: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation should have Apple Sign-In button integrated (iOS)
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:18 +30 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Interaction Tests with Firebase Registration form accepts text input
00:18 +31 -5: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation should be ready for Apple Sign-In button integration
00:18 +31 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:18 +31 -5: /home/runner/work/artbeat-app/artbeat-app/test/social_login_readiness_test.dart: Social Login Integration Tests UI Integration Preparation should be ready for Apple Sign-In button integration
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:18 +32 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
00:18 +33 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
00:18 +34 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_error_email_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_error_password_required] not found
00:18 +35 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
00:18 +36 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
00:18 +37 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Login button can be tapped
00:18 +38 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Registration button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found

Warning: A call to tap() with finder "Found 1 widget with type "ElevatedButton" (ignoring all but first): [
  ElevatedButton(style: ButtonStyle#ffc90(backgroundColor: Instance of '_WidgetStatePropertyWith<Color>', foregroundColor: WidgetStatePropertyAll(Color(alpha: 1.0000, red: 1.0000, green: 1.0000, blue: 1.0000, colorSpace: ColorSpace.sRGB)), padding: WidgetStatePropertyAll(EdgeInsets(24.0, 12.0, 24.0, 12.0)), shape: WidgetStatePropertyAll(RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.circular(8.0)))), dependencies: [IconTheme, InheritedCupertinoTheme, MediaQuery, _InheritedTheme, _LocalizationsScope-[GlobalKey#0d4d2]], state: _ButtonStyleState#6fa94),
]" derived an Offset (Offset(400.0, 690.0)) that would not hit test on the specified widget.
Maybe the widget is actually off-screen, or another widget is obscuring it, or the widget cannot receive pointer events.
Indeed, Offset(400.0, 690.0) is outside the bounds of the root of the render tree, Size(800.0, 600.0).
The finder corresponds to this RenderBox: RenderSemanticsAnnotations#8fbb1
The hit test result at that offset is: HitTestResult(HitTestEntry<HitTestTarget>#e07f8(_ReusableRenderView#5ab9e), HitTestEntry<HitTestTarget>#910f8(<AutomatedTestWidgetsFlutterBinding>))
#0      WidgetController._getElementPoint (package:flutter_test/src/controller.dart:2077:25)
#1      WidgetController.getCenter (package:flutter_test/src/controller.dart:1861:12)
#2      WidgetController.tap (package:flutter_test/src/controller.dart:1041:7)
#3      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart:251:26)
<asynchronous suspension>
#4      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#5      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
#6      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
To silence this warning, pass "warnIfMissed: false" to "tap()".
To make this warning fatal, set WidgetController.hitTestWarningShouldBeFatal to true.

00:18 +39 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests with Firebase Password reset button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email_required] not found
00:18 +40 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Authentication State Tests User authentication status check works
00:18 +41 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Authentication State Tests Session persistence works
00:18 +42 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) 1. AUTHENTICATION & ONBOARDING - Core UI Tests Authentication State Tests Logout functionality works
00:18 +43 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) Service Layer Tests with Firebase AuthService can be instantiated with mock Firebase
00:18 +44 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) Service Layer Tests with Firebase UserService works with fake Firestore
00:18 +45 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) Model Tests UserModel can be created with required fields
00:18 +46 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_firebase_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled) (tearDownAll)
00:20 +46 -5: loading /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart
00:21 +46 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite (setUpAll)
Firebase initialization warning in test: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore"., null, null)
00:21 +46 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.1: Artist Profile Display should fetch artist profile by user ID
00:22 +47 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.1: Artist Profile Display should handle missing artist profile gracefully
00:22 +48 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.2: View Artist Bio & Portfolio should retrieve artist bio and portfolio information
00:22 +49 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.2: View Artist Bio & Portfolio should fetch artist statistics (followers, views, sales)
00:22 +50 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.3: Follow/Unfollow Artist should create follow relationship between users
00:22 +51 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.3: Follow/Unfollow Artist should check if user is following artist
00:22 +52 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.3: Follow/Unfollow Artist should remove follow relationship when unfollowing
00:22 +53 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.4: Commission Artist should fetch artist commission settings
00:22 +54 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.4: Commission Artist should create commission request
00:22 +55 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.4: Commission Artist should allow artist to accept/reject commission
00:22 +56 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.5: Artist Dashboard should load artist dashboard with overview statistics
00:22 +57 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.5: Artist Dashboard should track recent activities on dashboard
00:22 +58 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.6: Manage Artist Artwork should fetch all artwork by artist
00:22 +59 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.6: Manage Artist Artwork should allow artist to upload new artwork
00:22 +60 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.6: Manage Artist Artwork should allow editing of artist artwork
00:22 +61 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.6: Manage Artist Artwork should allow deletion of artist artwork
00:22 +62 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.7: View Artist Analytics should fetch artist analytics dashboard data
00:22 +63 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.7: View Artist Analytics should track sales analytics over time
00:22 +64 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.8: View Artist Earnings should retrieve artist earnings summary
00:22 +65 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.8: View Artist Earnings should track earnings by source
00:22 +66 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.9: Manage Payout Accounts should retrieve artist payout accounts
00:22 +67 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.9: Manage Payout Accounts should allow adding new payout account
00:22 +68 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.9: Manage Payout Accounts should allow updating default payout account
00:22 +69 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.10: Request Payout should create payout request with validation
00:22 +70 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.10: Request Payout should track payout request status
00:22 +71 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite 8.10: Request Payout should retrieve payout history
00:22 +72 -5: /home/runner/work/artbeat-app/artbeat-app/test/artist_features_test.dart: ARTIST FEATURES - Comprehensive Test Suite (tearDownAll)
00:22 +72 -5: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch
Pending timers:
Timer (duration: 0:00:00.200000, periodic: false), created:
#0      new FakeTimer._ (package:fake_async/fake_async.dart:342:62)
#1      FakeAsync._createTimer (package:fake_async/fake_async.dart:260:29)
#2      FakeAsync.run.<anonymous closure> (package:fake_async/fake_async.dart:185:15)
#6      _SplashScreenState._checkAuthAndNavigate (package:artbeat_core/src/screens/splash_screen.dart:67:11)
#7      _SplashScreenState.initState (package:artbeat_core/src/screens/splash_screen.dart:32:5)
#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#237    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#238    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#239    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#704    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#705    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#706    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#707    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#708    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#709    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#710    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#711    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#712    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#713    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#714    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#715    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#716    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#717    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#718    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#719    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#720    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#721    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#722    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#723    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#724    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#725    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#726    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#727    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#728    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#729    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#730    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#731    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#732    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#733    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#734    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#735    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#736    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#737    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#738    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#739    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#740    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#741    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#742    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#743    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#744    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#745    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#746    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#749    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#750    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#751    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#752    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#753    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#754    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#755    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#756    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#757    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#758    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#759    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#760    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#761    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#762    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#763    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#764    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#765    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#766    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#767    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#768    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#769    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#770    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#771    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#774    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#775    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#776    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#779    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#780    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#781    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:12:22)
#782    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#783    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 8 frames from dart:async and package:stack_trace)

══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
A Timer is still pending even after the widget tree was disposed.
'package:flutter_test/src/binding.dart':
Failed assertion: line 1617 pos 12: '!timersPending'

When the exception was thrown, this was the stack:
#2      AutomatedTestWidgetsFlutterBinding._verifyInvariants (package:flutter_test/src/binding.dart:1617:12)
#3      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1078:7)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from class _AssertionError and package:stack_trace)

The test description was:
  ✅ Splash screen displays on app launch
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -6: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests ✅ Splash screen displays on app launch [E]
  Test failed. See exception logs above.
  The test description was: ✅ Splash screen displays on app launch
  
00:23 +72 -6: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Login screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:23:39

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:23:22)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "LoginScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:26:9)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 26
The test description was:
  Login screen displays correctly
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -7: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Login screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Login screen displays correctly
  
00:23 +72 -7: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Register screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:41:39

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _RegisterScreenState.initState (package:artbeat_auth/src/screens/register_screen.dart:37:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:41:22)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "RegisterScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:44:9)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 44
The test description was:
  Register screen displays correctly
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -8: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Register screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Register screen displays correctly
  
00:23 +72 -8: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Forgot Password screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:54:17

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _ForgotPasswordScreenState.initState (package:artbeat_auth/src/screens/forgot_password_screen.dart:31:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:53:22)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "ForgotPasswordScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:58:9)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 58
The test description was:
  Forgot Password screen displays correctly
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -9: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Forgot Password screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Forgot Password screen displays correctly
  
00:23 +72 -9: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Email verification screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:73:17

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      _EmailVerificationScreenState.initState (package:artbeat_auth/src/screens/email_verification_screen.dart:29:26)
#4      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#5      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#233    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#234    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#235    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#700    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#701    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#702    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#703    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#704    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#705    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#706    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#707    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#708    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#709    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#710    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#711    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#712    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#713    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#714    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#715    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#716    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#717    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#718    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#719    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#720    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#721    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#722    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#723    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#724    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#725    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#726    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#727    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#728    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#729    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#730    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#731    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#732    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#733    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#734    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#735    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#736    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#737    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#738    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#739    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#740    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#741    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#742    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#743    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#744    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#745    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#746    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#747    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#748    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#749    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#750    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#751    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#752    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#753    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#754    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#755    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#756    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#757    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#758    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#759    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#760    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#761    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#762    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#763    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#764    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#765    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#766    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#767    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#770    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#771    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#772    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#775    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#776    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#777    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:72:22)
#778    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#779    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "EmailVerificationScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:77:9)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 77
The test description was:
  Email verification screen displays correctly
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -10: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Email verification screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Email verification screen displays correctly
  
00:23 +72 -10: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Profile creation screen displays correctly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building ProfileCreateScreen(dirty):
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  ProfileCreateScreen
  ProfileCreateScreen:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:81:57

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      ProfileCreateScreen.build (package:artbeat_auth/src/screens/profile_create_screen.dart:15:31)
#4      StatelessElement.build (package:flutter/src/widgets/framework.dart:5791:49)
#5      ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5723:15)
#6      Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#7      ComponentElement._firstBuild (package:flutter/src/widgets/framework.dart:5705:5)
#8      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#236    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#237    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#238    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#703    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#704    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#705    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#706    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#707    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#708    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#709    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#710    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#711    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#712    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#713    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#714    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#715    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#716    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#717    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#718    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#719    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#720    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#721    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#722    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#723    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#724    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#725    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#726    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#727    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#728    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#729    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#730    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#731    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#732    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#733    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#734    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#735    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#736    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#737    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#738    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#739    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#740    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#741    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#742    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#743    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#744    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#745    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#746    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#747    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#748    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#749    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#750    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#751    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#752    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#753    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#754    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#755    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#756    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#757    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#758    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#759    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#760    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#761    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#762    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#763    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#764    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#765    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#766    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#767    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#768    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#769    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#770    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#773    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#774    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#775    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#778    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#779    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#780    main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:81:22)
#781    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#782    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -11: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Profile creation screen displays correctly [E]
  Test failed. See exception logs above.
  The test description was: Profile creation screen displays correctly
  
00:23 +72 -11: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Validation Tests Login form accepts text input
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:89:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:89:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -12: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Validation Tests Login form accepts text input [E]
  Test failed. See exception logs above.
  The test description was: Login form accepts text input
  
00:23 +72 -12: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Validation Tests Registration form accepts text input
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:109:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _RegisterScreenState.initState (package:artbeat_auth/src/screens/register_screen.dart:37:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:109:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -13: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Form Validation Tests Registration form accepts text input [E]
  Test failed. See exception logs above.
  The test description was: Registration form accepts text input
  
00:23 +72 -13: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Navigation Tests Login screen has navigation elements
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:132:13

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:131:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "LoginScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:142:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 142
The test description was:
  Login screen has navigation elements
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -14: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Navigation Tests Login screen has navigation elements [E]
  Test failed. See exception logs above.
  The test description was: Login screen has navigation elements
  
00:23 +72 -14: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Navigation Tests Registration screen has required navigation
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:156:13

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _RegisterScreenState.initState (package:artbeat_auth/src/screens/register_screen.dart:37:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:155:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "RegisterScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:165:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 165
The test description was:
  Registration screen has required navigation
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -15: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Navigation Tests Registration screen has required navigation [E]
  Test failed. See exception logs above.
  The test description was: Registration screen has required navigation
  
00:23 +72 -15: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests Login button can be tapped
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:171:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:171:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -16: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests Login button can be tapped [E]
  Test failed. See exception logs above.
  The test description was: Login button can be tapped
  
00:23 +72 -16: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests Registration button can be tapped
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:185:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _RegisterScreenState.initState (package:artbeat_auth/src/screens/register_screen.dart:37:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:185:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -17: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests Registration button can be tapped [E]
  Test failed. See exception logs above.
  The test description was: Registration button can be tapped
  
00:23 +72 -17: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests Password reset button can be tapped
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:198:19

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _ForgotPasswordScreenState.initState (package:artbeat_auth/src/screens/forgot_password_screen.dart:31:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:197:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -18: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Button Interaction Tests Password reset button can be tapped [E]
  Test failed. See exception logs above.
  The test description was: Password reset button can be tapped
  
00:23 +72 -18: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests UI Element Validation Password fields have visibility toggle
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:213:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:213:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "LoginScreen": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:225:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 225
The test description was:
  Password fields have visibility toggle
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -19: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests UI Element Validation Password fields have visibility toggle [E]
  Test failed. See exception logs above.
  The test description was: Password fields have visibility toggle
  
00:23 +72 -19: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests UI Element Validation Forms have proper validation structure
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:229:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _RegisterScreenState.initState (package:artbeat_auth/src/screens/register_screen.dart:37:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:229:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "Form": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:232:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 232
The test description was:
  Forms have proper validation structure
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -20: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests UI Element Validation Forms have proper validation structure [E]
  Test failed. See exception logs above.
  The test description was: Forms have proper validation structure
  
00:23 +72 -20: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Accessibility Tests Login screen has proper semantics
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:242:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:242:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "Scaffold": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:245:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 245
The test description was:
  Login screen has proper semantics
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -21: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Accessibility Tests Login screen has proper semantics [E]
  Test failed. See exception logs above.
  The test description was: Login screen has proper semantics
  
00:23 +72 -21: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Accessibility Tests Registration screen has proper semantics
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:250:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _RegisterScreenState.initState (package:artbeat_auth/src/screens/register_screen.dart:37:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:250:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "Scaffold": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:252:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 252
The test description was:
  Registration screen has proper semantics
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -22: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Accessibility Tests Registration screen has proper semantics [E]
  Test failed. See exception logs above.
  The test description was: Registration screen has proper semantics
  
00:23 +72 -22: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Error Handling UI Tests Forms can display error states
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:258:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:258:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following StateError was thrown running a test:
Bad state: No element

When the exception was thrown, this was the stack:
#0      Iterable.first (dart:core/iterable.dart:663:7)
#1      _FirstFinderMixin.filter (package:flutter_test/src/finders.dart:1332:28)
#3      Iterable.isEmpty (dart:core/iterable.dart:560:33)
#4      WidgetController._getElementPoint (package:flutter_test/src/controller.dart:2008:18)
#5      WidgetController.getCenter (package:flutter_test/src/controller.dart:1861:12)
#6      WidgetController.tap (package:flutter_test/src/controller.dart:1041:7)
#7      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:262:24)
<asynchronous suspension>
#8      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#9      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 2 frames from dart:async-patch and package:stack_trace)

The test description was:
  Forms can display error states
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -23: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Error Handling UI Tests Forms can display error states [E]
  Test failed. See exception logs above.
  The test description was: Forms can display error states
  
00:23 +72 -23: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Screen Layout Tests Splash screen has proper layout
Pending timers:
Timer (duration: 0:00:00.200000, periodic: false), created:
#0      new FakeTimer._ (package:fake_async/fake_async.dart:342:62)
#1      FakeAsync._createTimer (package:fake_async/fake_async.dart:260:29)
#2      FakeAsync.run.<anonymous closure> (package:fake_async/fake_async.dart:185:15)
#6      _SplashScreenState._checkAuthAndNavigate (package:artbeat_core/src/screens/splash_screen.dart:67:11)
#7      _SplashScreenState.initState (package:artbeat_core/src/screens/splash_screen.dart:32:5)
#8      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#9      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#237    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#238    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#239    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#704    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#705    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#706    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#707    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#708    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#709    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#710    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#711    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#712    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#713    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#714    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#715    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#716    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#717    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#718    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#719    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#720    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#721    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#722    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#723    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#724    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#725    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#726    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#727    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#728    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#729    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#730    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#731    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#732    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#733    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#734    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#735    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#736    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#737    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#738    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#739    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#740    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#741    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#742    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#743    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#744    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#745    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#746    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#749    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#750    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#751    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#752    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#753    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#754    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#755    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#756    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#757    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#758    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#759    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#760    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#761    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#762    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#763    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#764    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#765    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#766    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#767    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#768    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#769    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#770    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#771    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#774    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#775    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#776    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#779    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#780    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#781    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:273:24)
#782    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#783    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 8 frames from dart:async and package:stack_trace)

══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following assertion was thrown running a test:
A Timer is still pending even after the widget tree was disposed.
'package:flutter_test/src/binding.dart':
Failed assertion: line 1617 pos 12: '!timersPending'

When the exception was thrown, this was the stack:
#2      AutomatedTestWidgetsFlutterBinding._verifyInvariants (package:flutter_test/src/binding.dart:1617:12)
#3      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1078:7)
<asynchronous suspension>
<asynchronous suspension>
(elided 3 frames from class _AssertionError and package:stack_trace)

The test description was:
  Splash screen has proper layout
════════════════════════════════════════════════════════════════════════════════════════════════════
00:23 +72 -24: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Screen Layout Tests Splash screen has proper layout [E]
  Test failed. See exception logs above.
  The test description was: Splash screen has proper layout
  
00:23 +72 -24: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Screen Layout Tests Auth screens have consistent layout
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:282:41

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    MultiChildRenderObjectElement.mount (package:flutter/src/widgets/framework.dart:7185:32)
...     Normal element mounting (465 frames)
#701    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#702    Element.updateChild (package:flutter/src/widgets/framework.dart:3998:20)
#703    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#704    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#705    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#706    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#707    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#708    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#709    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#710    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#711    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#712    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#713    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#714    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#715    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#716    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#717    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#718    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#719    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#720    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#721    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#722    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#723    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#724    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#725    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#726    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#727    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#728    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#729    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#730    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#731    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#732    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#733    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#734    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#735    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#736    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#737    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#738    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#739    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#740    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#741    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#742    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#743    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#744    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#745    _RawViewElement._updateChild (package:flutter/src/widgets/view.dart:481:16)
#746    _RawViewElement.update (package:flutter/src/widgets/view.dart:568:5)
#747    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#748    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#749    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#750    StatelessElement.update (package:flutter/src/widgets/framework.dart:5797:5)
#751    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#752    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#753    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#754    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#755    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#756    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#757    RootElement._rebuild (package:flutter/src/widgets/binding.dart:1716:16)
#758    RootElement.update (package:flutter/src/widgets/binding.dart:1694:5)
#759    RootElement.performRebuild (package:flutter/src/widgets/binding.dart:1708:7)
#760    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#761    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#762    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#763    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#764    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#765    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#766    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#767    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#768    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#771    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#772    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#773    WidgetTester.pumpWidget.<anonymous closure> (package:flutter_test/src/widget_tester.dart:598:22)
#776    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#777    WidgetTester.pumpWidget (package:flutter_test/src/widget_tester.dart:595:27)
#778    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:282:24)
#779    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#780    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "Scaffold": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:284:11)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart line 284
The test description was:
  Auth screens have consistent layout
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:24 +72 -25: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Screen Layout Tests Auth screens have consistent layout [E]
  Test failed. See exception logs above.
  The test description was: Auth screens have consistent layout
  
00:24 +72 -25: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Integration Readiness Tests Screens handle navigation properly
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following FirebaseException was thrown building Builder:
[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()

The relevant error-causing widget was:
  MaterialApp
  MaterialApp:file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:297:13

When the exception was thrown, this was the stack:
#0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      new AuthService (package:artbeat_auth/src/services/auth_service.dart:24:34)
#4      _LoginScreenState.initState (package:artbeat_auth/src/screens/login_screen.dart:35:42)
#5      StatefulElement._firstBuild (package:flutter/src/widgets/framework.dart:5852:55)
#6      ComponentElement.mount (package:flutter/src/widgets/framework.dart:5699:5)
...     Normal element mounting (228 frames)
#234    Element.inflateWidget (package:flutter/src/widgets/framework.dart:4548:16)
#235    MultiChildRenderObjectElement.inflateWidget (package:flutter/src/widgets/framework.dart:7169:36)
#236    Element.updateChild (package:flutter/src/widgets/framework.dart:4004:18)
#237    Element.updateChildren (package:flutter/src/widgets/framework.dart:4203:32)
#238    MultiChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7202:17)
#239    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#240    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#241    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#242    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#243    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#244    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#245    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#246    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#247    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#248    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#249    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#250    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#251    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#252    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#253    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#254    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#255    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#256    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#257    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#258    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#259    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#260    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#261    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#262    _InheritedNotifierElement.update (package:flutter/src/widgets/inherited_notifier.dart:108:11)
#263    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#264    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#265    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#266    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#267    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#268    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#269    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#270    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#271    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#272    StatefulElement.update (package:flutter/src/widgets/framework.dart:5909:5)
#273    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#274    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#275    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#276    SingleChildRenderObjectElement.update (package:flutter/src/widgets/framework.dart:7025:14)
#277    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#278    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#279    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#280    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#281    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#282    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#283    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#284    ProxyElement.update (package:flutter/src/widgets/framework.dart:6051:5)
#285    Element.updateChild (package:flutter/src/widgets/framework.dart:3982:15)
#286    ComponentElement.performRebuild (package:flutter/src/widgets/framework.dart:5747:16)
#287    StatefulElement.performRebuild (package:flutter/src/widgets/framework.dart:5884:11)
#288    Element.rebuild (package:flutter/src/widgets/framework.dart:5435:7)
#289    BuildScope._tryRebuild (package:flutter/src/widgets/framework.dart:2695:15)
#290    BuildScope._flushDirtyElements (package:flutter/src/widgets/framework.dart:2752:11)
#291    BuildOwner.buildScope (package:flutter/src/widgets/framework.dart:3056:18)
#292    AutomatedTestWidgetsFlutterBinding.drawFrame (package:flutter_test/src/binding.dart:1506:19)
#293    RendererBinding._handlePersistentFrameCallback (package:flutter/src/rendering/binding.dart:495:5)
#294    SchedulerBinding._invokeFrameCallback (package:flutter/src/scheduler/binding.dart:1434:15)
#295    SchedulerBinding.handleDrawFrame (package:flutter/src/scheduler/binding.dart:1347:9)
#296    AutomatedTestWidgetsFlutterBinding.pump.<anonymous closure> (package:flutter_test/src/binding.dart:1335:9)
#299    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#300    AutomatedTestWidgetsFlutterBinding.pump (package:flutter_test/src/binding.dart:1324:27)
#301    WidgetTester.pump.<anonymous closure> (package:flutter_test/src/widget_tester.dart:652:53)
#304    TestAsyncUtils.guard (package:flutter_test/src/test_async_utils.dart:74:41)
#305    WidgetTester.pump (package:flutter_test/src/widget_tester.dart:652:27)
#306    main.<anonymous closure>.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:313:24)
<asynchronous suspension>
#307    testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#308    TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 5 frames from dart:async and package:stack_trace)

════════════════════════════════════════════════════════════════════════════════════════════════════
00:24 +72 -26: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests 1. AUTHENTICATION & ONBOARDING - Core UI Tests Integration Readiness Tests Screens handle navigation properly [E]
  Test failed. See exception logs above.
  The test description was: Screens handle navigation properly
  
00:24 +72 -26: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests Service Layer Tests AuthService can be instantiated
00:24 +72 -27: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests Service Layer Tests AuthService can be instantiated [E]
  [core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
  package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart 190:5  MethodChannelFirebase.app
  package:firebase_core/src/firebase.dart 91:41                                                   Firebase.app
  package:firebase_auth/src/firebase_auth.dart 38:47                                              FirebaseAuth.instance
  package:artbeat_auth/src/services/auth_service.dart 24:34                                       new AuthService
  test/auth_onboarding_complete_test.dart 321:29                                                  main.<fn>.<fn>.<fn>
  
00:24 +72 -27: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests Service Layer Tests UserService can be instantiated
Error details: [core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
Stack trace: #0      MethodChannelFirebase.app (package:firebase_core_platform_interface/src/method_channel/method_channel_firebase.dart:190:5)
#1      Firebase.app (package:firebase_core/src/firebase.dart:91:41)
#2      FirebaseAuth.instance (package:firebase_auth/src/firebase_auth.dart:38:47)
#3      UserService._initializeFirebase (package:artbeat_core/src/services/user_service.dart:71:28)
#4      new UserService._internal (package:artbeat_core/src/services/user_service.dart:30:5)
#5      UserService._instance (package:artbeat_core/src/services/user_service.dart:17:52)
#6      UserService._instance (package:artbeat_core/src/services/user_service.dart)
#7      new UserService (package:artbeat_core/src/services/user_service.dart:20:12)
#8      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart:326:29)
#9      Declarer.test.<anonymous closure>.<anonymous closure> (package:test_api/src/backend/declarer.dart:242:19)
<asynchronous suspension>
#10     Declarer.test.<anonymous closure> (package:test_api/src/backend/declarer.dart:240:7)
<asynchronous suspension>
#11     Invoker._waitForOutstandingCallbacks.<anonymous closure> (package:test_api/src/backend/invoker.dart:282:9)
<asynchronous suspension>

00:24 +73 -27: /home/runner/work/artbeat-app/artbeat-app/test/auth_onboarding_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests Model Tests UserModel can be created with required fields
00:25 +74 -27: /home/runner/work/artbeat-app/artbeat-app/test/widget_test.dart: Core Widget Tests UserProgressCard displays correctly
00:25 +75 -27: /home/runner/work/artbeat-app/artbeat-app/test/widget_test.dart: Core Widget Tests UserProgressCard shows streak information
00:25 +76 -27: /home/runner/work/artbeat-app/artbeat-app/test/widget_test.dart: Error Handling Tests ErrorBoundary handles errors gracefully
00:25 +77 -27: /home/runner/work/artbeat-app/artbeat-app/test/widget_test.dart: Utility Tests AppLogger can be initialized
00:25 +78 -27: /home/runner/work/artbeat-app/artbeat-app/test/widget_test.dart: Utility Tests PerformanceMonitor can start timer
00:26 +79 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features Art Walk map displays correctly with markers
00:27 +80 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features Art Walk list displays all art walks
00:27 +81 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features Browse art walks - retrieve all public art walks
00:27 +82 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features Filter art walks by difficulty level
00:27 +83 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features Search art walks by title
00:27 +84 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features View art walk detail page loads with full information
00:27 +85 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features See checkpoint locations from public art collection
00:27 +86 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features View art walk route and navigation data
00:27 +87 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Discovery Features View art walk difficulty and duration estimates
00:27 +88 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Start art walk - create progress record
00:27 +89 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features GPS tracking is enabled during art walk participation
00:27 +90 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Checkpoint detection - track checkpoint completion
00:27 +91 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Checkpoint photos display from completed artworks
00:27 +92 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Navigation updates - real-time location tracking
00:27 +93 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Timer and progress tracking - monitor completion percentage
00:27 +94 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Complete art walk - finalize progress and record completion
00:27 +95 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Art walk celebration screen displays with completion data
00:27 +96 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Share art walk results to social feed
00:27 +97 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features Save or bookmark art walk for later
00:27 +98 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features View saved art walks for logged-in user
00:27 +99 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features View completed art walks history
00:27 +100 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features View popular art walks by completion count
00:27 +101 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Participation Features View nearby art walks based on current location
00:27 +102 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Create new art walk - initialize with title and description
00:27 +103 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Add checkpoints to art walk
00:27 +104 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Set art walk route with multiple checkpoints
00:27 +105 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Add descriptions to art walk and checkpoints
00:27 +106 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Upload artwork to art walk checkpoints
00:27 +107 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Set difficulty level for art walk
00:27 +108 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Publish art walk to make it public
00:27 +109 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Edit existing art walk
00:27 +110 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features Delete art walk
00:27 +111 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Creation Features View art walk analytics and metrics
00:27 +112 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Integration Tests Complete workflow: Create, start, and complete art walk
00:27 +113 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Integration Tests Complex discovery scenario: Search, filter, bookmark, start walk
00:27 +114 -27: /home/runner/work/artbeat-app/artbeat-app/test/art_walk_system_test.dart: Art Walk System - Integration Tests Full creation workflow with all optional fields
00:27 +115 -27: loading /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart
00:29 +115 -27: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Splash screen displays and animates
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: at least one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "Container": []>
   Which: means none were found but some were expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure>.<anonymous closure> (file:///home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart:16:9)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1059:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart line 16
The test description was:
  ✅ Splash screen displays and animates
════════════════════════════════════════════════════════════════════════════════════════════════════
00:29 +115 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Splash screen displays and animates [E]
  Test failed. See exception logs above.
  The test description was: ✅ Splash screen displays and animates
  
00:29 +115 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Login screen displays correctly
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:30 +116 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Registration screen displays correctly
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
00:30 +117 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Forgot Password screen displays correctly
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
00:30 +118 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Email verification screen displays correctly
00:30 +119 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 1. AUTHENTICATION SCREENS - UI Tests ✅ Profile creation screen displays correctly
00:30 +120 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 2. FORM INTERACTIONS - Input Tests ✅ Login form accepts email input
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:30 +121 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 2. FORM INTERACTIONS - Input Tests ✅ Login form accepts password input
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:30 +122 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 2. FORM INTERACTIONS - Input Tests ✅ Registration form accepts user input
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
00:31 +123 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 2. FORM INTERACTIONS - Input Tests ✅ Forgot password form accepts email
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
00:31 +124 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 3. BUTTON INTERACTIONS - Action Tests ✅ Login button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
Warning: Easy Localization] [WARNING] Localization key [auth_error_email_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_error_password_required] not found
00:31 +125 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 3. BUTTON INTERACTIONS - Action Tests ✅ Registration button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password_required] not found
00:31 +126 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 3. BUTTON INTERACTIONS - Action Tests ✅ Password reset button can be tapped
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email_required] not found
00:31 +127 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 4. FORM VALIDATION - Error Handling Tests ✅ Login form handles empty submission
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
Warning: Easy Localization] [WARNING] Localization key [auth_error_email_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_error_password_required] not found
00:31 +128 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 4. FORM VALIDATION - Error Handling Tests ✅ Registration form handles empty submission
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password_required] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password_required] not found
00:31 +129 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 5. UI ELEMENT VALIDATION - Layout Tests ✅ All auth screens have proper Scaffold structure
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
00:31 +130 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 5. UI ELEMENT VALIDATION - Layout Tests ✅ Forms have proper validation structure
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password_back_to_login] not found
00:31 +131 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 5. UI ELEMENT VALIDATION - Layout Tests ✅ Password fields have visibility toggle capability
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:32 +132 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 6. MOCK AUTHENTICATION STATE TESTS ✅ Mock user creation works
00:32 +133 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 6. MOCK AUTHENTICATION STATE TESTS ✅ Mock auth service integration
00:32 +134 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 6. MOCK AUTHENTICATION STATE TESTS ✅ Mock Firestore integration
00:32 +135 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 7. SERVICE LAYER TESTS ✅ Mock Auth service integration works
00:32 +136 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 7. SERVICE LAYER TESTS ✅ Test data structures work correctly
00:32 +137 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 8. ACCESSIBILITY TESTS ✅ Login screen is accessible
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:32 +138 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 8. ACCESSIBILITY TESTS ✅ Registration screen is accessible
Warning: Easy Localization] [WARNING] Localization key [auth_register_title] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_subtitle] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_first_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_last_name] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_confirm_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_agree_prefix] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_terms_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_and] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_privacy_link] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_button] not found
Warning: Easy Localization] [WARNING] Localization key [auth_register_login_link] not found
00:32 +139 -28: /home/runner/work/artbeat-app/artbeat-app/test/auth_complete_test.dart: 🎯 ArtBeat Authentication & Onboarding Tests (Complete) 9. NAVIGATION READINESS TESTS ✅ Screens handle MaterialApp context
Warning: Easy Localization] [WARNING] Localization key [auth_welcome] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_continue] not found
Warning: Easy Localization] [WARNING] Localization key [auth_email] not found
Warning: Easy Localization] [WARNING] Localization key [auth_password] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in] not found
Warning: Easy Localization] [WARNING] Localization key [auth_create_account] not found
Warning: Easy Localization] [WARNING] Localization key [auth_forgot_password] not found
Warning: Easy Localization] [WARNING] Localization key [common_or] not found
Warning: Easy Localization] [WARNING] Localization key [auth_sign_in_with_google] not found
00:33 +140 -28: Some tests failed.
Error: Process completed with exit code 1.