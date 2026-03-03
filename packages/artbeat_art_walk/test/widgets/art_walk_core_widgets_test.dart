import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GradientCTAButton', () {
    testWidgets('renders label and triggers callback when tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: GradientCTAButton(
              label: 'Start Walk',
              icon: Icons.directions_walk,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Walk'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows spinner and disables tap when loading', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: GradientCTAButton(
              label: 'Loading',
              loading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, isFalse);
    });
  });

  group('GlassCard', () {
    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Card'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
