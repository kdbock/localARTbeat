import 'package:artbeat/src/routing/handlers/direct_route_handler.dart';
import 'package:artbeat/src/screens/user_onboarding_flow_screen.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  Widget buildHarness({String initialRoute = '/'}) => MaterialApp(
    initialRoute: initialRoute,
    routes: {
      '/': (_) => const UserOnboardingFlowScreen(),
      AppRoutes.dashboard: (_) => const Scaffold(body: Text('Dashboard')),
    },
    onGenerateRoute: (settings) {
      final route = const DirectRouteHandler().handleRoute(settings);
      return route;
    },
  );

  testWidgets('shows hook screen with fan/artist choices', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(
      find.text('Discover, photograph, and share public art.'),
      findsOneWidget,
    );
    expect(find.text('Explore as a Fan'), findsOneWidget);
    expect(find.text("I'm an Artist"), findsOneWidget);
  });

  testWidgets('artist choice goes to one-photo screen', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm an Artist"));
    await tester.pumpAndSettle();

    expect(find.text('Upload one photo of your work.'), findsOneWidget);
    expect(find.text('Choose Photo'), findsOneWidget);
  });

  testWidgets('skip marks onboarding complete and enters dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(await OnboardingService().isOnboardingCompleted(), isTrue);
  });

  testWidgets('legacy onboarding route resolves to user onboarding screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(initialRoute: '/2025_modern_onboarding'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UserOnboardingFlowScreen), findsOneWidget);
  });

  testWidgets('new onboarding route resolves to user onboarding screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(initialRoute: AppRoutes.userOnboarding),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UserOnboardingFlowScreen), findsOneWidget);
  });
}
