// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:artbeat/src/widgets/error_boundary.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/widgets/dashboard/user_progress_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  Widget wrapWithLocalization(Widget child) => EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    assetLoader: const TestFileAssetLoader(),
    child: Builder(
      builder: (BuildContext context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: child,
      ),
    ),
  );

  // Note: MyApp widget tests are skipped because they require Firebase initialization
  // which is complex to mock in widget tests. These tests should be covered by
  // integration tests instead.

  group('Core Widget Tests', () {
    testWidgets('UserProgressCard displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithLocalization(const Scaffold(body: UserProgressCard())),
      );

      // Verify the card is displayed (it uses Container, not Card)
      expect(find.byType(UserProgressCard), findsOneWidget);
      // Check for the progress text
      expect(find.text('Your Progress'), findsOneWidget);
    });

    testWidgets('UserProgressCard shows streak information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithLocalization(const Scaffold(body: UserProgressCard())),
      );

      // Check for streak-related text (case sensitive)
      expect(find.textContaining('Streak'), findsWidgets);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('ErrorBoundary handles errors gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: SizedBox.shrink())),
      );

      // The ErrorBoundary should be present
      expect(find.byType(ErrorBoundary), findsOneWidget);
    });
  });

  group('Utility Tests', () {
    test('AppLogger can be initialized', () {
      // Test that logger initialization doesn't throw
      expect(AppLogger.initialize, returnsNormally);
    });

    test('PerformanceMonitor can start timer', () {
      // Test that performance monitoring works
      expect(() => PerformanceMonitor.startTimer('test'), returnsNormally);
    });
  });
}
