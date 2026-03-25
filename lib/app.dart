import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app_providers.dart';
import 'src/bootstrap/app_error_handling.dart';
import 'src/routing/app_router.dart';
import 'src/widgets/error_boundary.dart';

/// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    debugPrint('🧭 MyApp.build() entered');
    try {
      return ErrorBoundary(
        onError: (error, stackTrace) {
          if (isExpectedMissingImageError(error)) {
            logExpectedMissingImageError(error);
            return;
          }
          core.AppLogger.error('❌ App-level error caught: $error');
          core.AppLogger.error('❌ Stack trace: $stackTrace');
        },
        child: MultiProvider(
          providers: createAppProviders(),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'ARTbeat',
            theme: ThemeData.light(),
            initialRoute: core.AppRoutes.splash,
            onGenerateRoute: _appRouter.onGenerateRoute,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            // navigatorObservers: [NavigationOverlay.createObserver(context)],
          ),
        ),
      );
    } on Exception catch (e, s) {
      core.AppLogger.error('Error in MyApp build: $e');
      core.AppLogger.error('Stack: $s');
      return MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      );
    }
  }
}
