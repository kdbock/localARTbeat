import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_core/src/widgets/quick_navigation_fab.dart';

void main() {
  Widget _buildApp({
    required Widget child,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      home: Scaffold(body: Stack(children: [child])),
      routes: routes ?? {},
    );
  }

  testWidgets('opens navigation sheet and calls custom onNavigate callback', (
    tester,
  ) async {
    String? navigatedRoute;

    await tester.pumpWidget(
      _buildApp(
        child: QuickNavigationFAB(
          onNavigate: (route) => navigatedRoute = route,
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Core'), findsOneWidget);
    expect(find.text('drawer_dashboard'), findsOneWidget);

    await tester.tap(find.text('drawer_dashboard'));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/dashboard');
    expect(find.text('Core'), findsNothing);
  });

  testWidgets(
    'navigates with Navigator.pushNamed when callback is not provided',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: const QuickNavigationFAB(),
          routes: {
            '/dashboard': (_) => const Scaffold(body: Text('dashboard-screen')),
          },
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('drawer_dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('dashboard-screen'), findsOneWidget);
    },
  );
}
