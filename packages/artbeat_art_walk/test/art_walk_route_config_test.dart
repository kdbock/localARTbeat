import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArtWalkRouteConfig', () {
    test('routes map contains expected static entries', () {
      expect(ArtWalkRouteConfig.routes.containsKey(ArtWalkRoutes.map), isTrue);
      expect(ArtWalkRouteConfig.routes.containsKey(ArtWalkRoutes.list), isTrue);
      expect(
        ArtWalkRouteConfig.routes.containsKey(ArtWalkRoutes.dashboard),
        isTrue,
      );
      expect(
        ArtWalkRouteConfig.routes.containsKey(ArtWalkRoutes.instantDiscovery),
        isTrue,
      );
    });

    test('generateRoute returns null for unknown route', () {
      final route = ArtWalkRouteConfig.generateRoute(
        const RouteSettings(name: '/unknown'),
      );

      expect(route, isNull);
    });

    testWidgets(
      'generateRoute returns fallback celebration screen when args missing',
      (tester) async {
        final route = ArtWalkRouteConfig.generateRoute(
          const RouteSettings(
            name: ArtWalkRoutes.celebration,
            arguments: <String, dynamic>{},
          ),
        );

        expect(route, isA<MaterialPageRoute<dynamic>>());

        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(route!);
              });
              return const SizedBox.shrink();
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        expect(find.text('Art walk celebration data missing'), findsOneWidget);
      },
    );
  });
}
