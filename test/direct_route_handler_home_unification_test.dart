import 'package:artbeat/src/routing/handlers/direct_route_handler.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectRouteHandler home unification', () {
    test('canonical dashboard route resolves', () {
      final route = const DirectRouteHandler().handleRoute(
        const RouteSettings(name: AppRoutes.dashboard),
      );

      expect(route, isNotNull);
    });

    test('legacy old-dashboard route remains debug-gated route definition', () {
      final route = const DirectRouteHandler().handleRoute(
        const RouteSettings(name: '/old-dashboard'),
      );

      expect(route, isNotNull);
    });
  });
}
