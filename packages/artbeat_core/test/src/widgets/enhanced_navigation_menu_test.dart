import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_core/src/widgets/enhanced_navigation_menu.dart';

void main() {
  Widget _buildMenu(void Function(String) onNavigate) {
    return MaterialApp(
      home: Scaffold(body: EnhancedNavigationMenu(onNavigate: onNavigate)),
    );
  }

  testWidgets('renders tab shell and default user header without provider', (
    tester,
  ) async {
    await tester.pumpWidget(_buildMenu((_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Core'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('USER'), findsOneWidget);
  });

  testWidgets('core feature tile triggers onNavigate callback', (tester) async {
    String? navigatedRoute;
    await tester.pumpWidget(_buildMenu((route) => navigatedRoute = route));
    await tester.pumpAndSettle();

    await tester.tap(find.text('drawer_dashboard'));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/dashboard');
  });

  testWidgets('settings tab route item triggers onNavigate callback', (
    tester,
  ) async {
    String? navigatedRoute;
    await tester.pumpWidget(_buildMenu((route) => navigatedRoute = route));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account Settings'));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/settings/account');
  });
}
