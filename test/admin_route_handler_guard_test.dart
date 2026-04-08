import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat/src/routing/handlers/admin_route_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _buildFromRoute(Route<dynamic>? route) {
    final materialRoute = route as MaterialPageRoute<dynamic>?;
    expect(materialRoute, isNotNull);
    return MaterialApp(home: Builder(builder: materialRoute!.builder));
  }

  testWidgets('blocks unauthorized admin navigation', (tester) async {
    final handler = AdminRouteHandler(adminAccessChecker: () async => false);
    final route = handler.handleRoute(
      const RouteSettings(name: core.AppRoutes.adminUsers),
    );

    await tester.pumpWidget(_buildFromRoute(route));
    await tester.pump();

    expect(find.text('Admin access required'), findsOneWidget);
    expect(find.byType(admin.ModernUnifiedAdminDashboard), findsNothing);
  });

  testWidgets('allows authorized admin navigation', (tester) async {
    final handler = AdminRouteHandler(adminAccessChecker: () async => true);
    const settings = RouteSettings(name: '/admin/unknown-feature');
    final route = handler.handleRoute(
      settings,
    );

    expect(route, isNotNull);
    expect(route, isA<MaterialPageRoute<dynamic>>());
    final materialRoute = route! as MaterialPageRoute<dynamic>;
    expect(materialRoute.settings.name, settings.name);
  });
}
