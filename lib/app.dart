import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/routing/app_router.dart';
import 'src/services/firebase_initializer.dart';
import 'src/widgets/error_boundary.dart';

/// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    _setupGlobalErrorHandling();
  }
  final _firebaseInitializer = FirebaseInitializer();
  final _appRouter = AppRouter();

  void _setupGlobalErrorHandling() {
    // Set up global error handler for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      final error = details.exception;
      final errorString = error.toString();

      // Filter out expected 404 errors for missing artwork images
      final isExpected404 =
          errorString.contains('statusCode: 404') &&
          (errorString.contains('firebasestorage.googleapis.com') ||
              errorString.contains('firebase') ||
              errorString.contains('artwork') ||
              errorString.contains('HttpException'));

      if (isExpected404) {
        // Log 404 errors at debug level only
        if (kDebugMode) {
          debugPrint(
            '🖼️ Missing image (404): ${errorString.split(',').first}',
          );
        }
        // Don't show these errors in release mode
        return;
      }

      // For other errors, use the default Flutter error handling
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _firebaseInitializer.ensureInitialized(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Error initializing app: ${snapshot.error}'),
            ),
          ),
        );
      }

      return ErrorBoundary(
        onError: (error, stackTrace) {
          // Filter out expected 404 errors for missing artwork images
          final errorString = error.toString();
          final isExpected404 =
              errorString.contains('statusCode: 404') &&
              (errorString.contains('firebasestorage.googleapis.com') ||
                  errorString.contains('firebase') ||
                  errorString.contains('artwork') ||
                  errorString.contains('HttpException'));

          if (isExpected404) {
            // Log 404 errors at debug level only
            if (kDebugMode) {
              debugPrint(
                '🖼️ Missing image (404): ${errorString.split(',').first}',
              );
            }
          } else {
            // Log other errors normally
            AppLogger.error('❌ App-level error caught: $error');
            AppLogger.error('❌ Stack trace: $stackTrace');
          }
        },
        child: MultiProvider(
          providers: [
            // Core providers
            ChangeNotifierProvider<core.UserService>.value(
              value: core.UserService(),
            ),
            Provider<AuthService>(create: (_) => AuthService(), lazy: true),
            ChangeNotifierProvider<core.ConnectivityService>(
              create: (_) => core.ConnectivityService(),
              lazy: false,
            ),
            Provider<ThemeData>(
              create: (_) => core.ArtbeatTheme.lightTheme,
              lazy: false,
            ),
            // Content Engagement Service
            ChangeNotifierProvider<core.ContentEngagementService>(
              create: (_) => core.ContentEngagementService(),
              lazy: true,
            ),
            ChangeNotifierProvider<messaging.ChatService>(
              create: (_) => messaging.ChatService(),
              lazy: true, // Changed to lazy to prevent early Firebase access
            ),
            // Message Reaction Service for emoji reactions
            ChangeNotifierProvider<messaging.MessageReactionService>(
              create: (_) => messaging.MessageReactionService(),
              lazy: true,
            ),
            ChangeNotifierProvider<core.MessagingProvider>(
              create: (context) =>
                  core.MessagingProvider(context.read<messaging.ChatService>()),
              lazy: true,
            ),
            // Presence Service for online status
            Provider<messaging.PresenceService>(
              create: (_) => messaging.PresenceService(),
              lazy: false, // Start immediately to track presence
            ),
            // Presence Provider for UI components
            ChangeNotifierProvider<messaging.PresenceProvider>(
              create: (context) => messaging.PresenceProvider(
                context.read<messaging.PresenceService>(),
              ),
              lazy: false,
            ),
            // Community providers
            ChangeNotifierProvider<CommunityService>(
              create: (_) => CommunityService(),
              lazy: true, // Changed to lazy to prevent early Firebase access
            ),
            ChangeNotifierProvider<core.CommunityProvider>(
              create: (_) => core.CommunityProvider(),
              lazy: true,
            ),
            // Search controller
            ChangeNotifierProvider<core.SearchController>(
              create: (_) => core.SearchController(),
              lazy: true,
            ),
            // Additional service providers for DashboardViewModel
            Provider<events.EventService>(
              create: (_) => events.EventService(),
              lazy: true,
            ),
            Provider<ArtworkService>(
              create: (_) => ArtworkService(),
              lazy: true,
            ),
            Provider<ArtWalkService>(
              create: (_) => ArtWalkService(),
              lazy: true,
            ),
            Provider<ArtWalkProgressService>(
              create: (_) => ArtWalkProgressService(),
              lazy: true,
            ),
            Provider<ArtWalkNavigationService>(
              create: (_) => ArtWalkNavigationService(),
              lazy: true,
            ),
            Provider<AchievementService>(
              create: (_) => AchievementService(),
              lazy: true,
            ),
            Provider<AudioNavigationService>(
              create: (_) => AudioNavigationService(),
              lazy: true,
            ),
            Provider<SocialService>(
              create: (_) => SocialService(),
              lazy: true,
            ),
            Provider<InstantDiscoveryService>(
              create: (_) => InstantDiscoveryService(),
              lazy: true,
            ),
            Provider<ChallengeService>(
              create: (_) => ChallengeService(),
              lazy: true,
            ),
            Provider<WeeklyGoalsService>(
              create: (_) => WeeklyGoalsService(),
              lazy: true,
            ),
            Provider<RewardsService>(
              create: (_) => RewardsService(),
              lazy: true,
            ),
            Provider<capture.CaptureService>(
              create: (_) => capture.CaptureService(),
              lazy: true,
            ),
            ChangeNotifierProvider<core.SubscriptionService>.value(
              value: core.SubscriptionService(),
            ),
            // Dashboard ViewModel - Create after required services
            ChangeNotifierProxyProvider6<
              events.EventService,
              ArtworkService,
              ArtWalkService,
              core.SubscriptionService,
              core.UserService,
              capture.CaptureService,
              core.DashboardViewModel
            >(
              create: (_) => core.DashboardViewModel(
                eventService: events.EventService(),
                artworkService: ArtworkService(),
                artWalkService: ArtWalkService(),
                subscriptionService: core.SubscriptionService(),
                userService: core.UserService(),
                captureService: capture.CaptureService(),
              ),
              update:
                  (
                    _,
                    events.EventService eventService,
                    ArtworkService artworkService,
                    ArtWalkService artWalkService,
                    core.SubscriptionService subscriptionService,
                    core.UserService userService,
                    capture.CaptureService captureService,
                    previous,
                  ) =>
                      previous ??
                      core.DashboardViewModel(
                        eventService: eventService,
                        artworkService: artworkService,
                        artWalkService: artWalkService,
                        subscriptionService: subscriptionService,
                        userService: userService,
                        captureService: captureService,
                      ),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'ARTbeat',
            theme: core.ArtbeatTheme.lightTheme,
            initialRoute: '/splash',
            onGenerateRoute: _appRouter.onGenerateRoute,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      );
    },
  );
}
