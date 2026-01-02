import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_capture/artbeat_capture.dart' as capture;
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'routing/app_router.dart';
import 'widgets/error_boundary.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final navigatorKey = GlobalKey<NavigatorState>();
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) => FutureBuilder(
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _buildErrorApp(snapshot.error.toString());
      }

      if (snapshot.connectionState != ConnectionState.done) {
        return _buildLoadingApp();
      }

      return _buildMainApp();
    }, future: null,
  );

  /// Builds the error state app
  Widget _buildErrorApp(String error) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error initializing app',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );

  /// Builds the loading state app
  Widget _buildLoadingApp() => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                core.ArtbeatTheme.lightTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Initializing ARTbeat...'),
          ],
        ),
      ),
    ),
  );

  /// Builds the main application with all providers
  Widget _buildMainApp() => ErrorBoundary(
    onError: (Object error, StackTrace stackTrace) {
      core.AppLogger.error('❌ App-level error caught: $error');
      core.AppLogger.error('❌ Stack trace: $stackTrace');
    },
    child: MultiProvider(
      providers: _createProviders(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ARTbeat',
        theme: core.ArtbeatTheme.lightTheme,
        initialRoute: '/splash',
        onGenerateRoute: _appRouter.onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );

  /// Creates all providers for the app
  List<SingleChildWidget> _createProviders() => [
    // Core providers
    ChangeNotifierProvider<core.UserService>(
      create: (_) => core.UserService(),
      lazy: true,
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

    // Messaging providers
    ChangeNotifierProvider<messaging.ChatService>(
      create: (_) => messaging.ChatService(),
      lazy: true,
    ),
    ChangeNotifierProvider<core.MessagingProvider>(
      create: (context) =>
          core.MessagingProvider(context.read<messaging.ChatService>()),
      lazy: true,
    ),
    Provider<messaging.PresenceService>(
      create: (_) => messaging.PresenceService(),
      lazy: false,
    ),
    ChangeNotifierProvider<messaging.PresenceProvider>(
      create: (context) =>
          messaging.PresenceProvider(context.read<messaging.PresenceService>()),
      lazy: false,
    ),

    // Community providers
    ChangeNotifierProvider<CommunityService>(
      create: (_) => CommunityService(),
      lazy: true,
    ),
    ChangeNotifierProvider<core.CommunityProvider>(
      create: (_) => core.CommunityProvider(),
      lazy: true,
    ),

    // Additional service providers for DashboardViewModel
    Provider<events.EventService>(
      create: (_) => events.EventService(),
      lazy: true,
    ),
    Provider<ArtworkService>(create: (_) => ArtworkService(), lazy: true),
    Provider<ArtWalkService>(create: (_) => ArtWalkService(), lazy: true),
    Provider<ChallengeService>(create: (_) => ChallengeService(), lazy: true),
    Provider<capture.CaptureService>(
      create: (_) => capture.CaptureService(),
      lazy: true,
    ),
    ChangeNotifierProvider<core.SubscriptionService>.value(
      value: core.SubscriptionService(),
    ),

    // Dashboard ViewModel
    ChangeNotifierProvider<core.DashboardViewModel>(
      create: (context) => core.DashboardViewModel(
        eventService: context.read<events.EventService>(),
        artworkService: context.read<ArtworkService>(),
        artWalkService: context.read<ArtWalkService>(),
        subscriptionService: context.read<core.SubscriptionService>(),
        userService: context.read<core.UserService>(),
        captureService: context.read<capture.CaptureService>(),
      ),
      lazy: true,
    ),
  ];
}
