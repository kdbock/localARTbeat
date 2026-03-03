import 'package:artbeat_artwork/src/models/artwork_model.dart';
import 'package:artbeat_artwork/src/widgets/artwork_moderation_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders display name and icon for status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArtworkModerationStatusChip(
            status: ArtworkModerationStatus.approved,
          ),
        ),
      ),
    );

    expect(find.text('Approved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('hides icon when showIcon is false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArtworkModerationStatusChip(
            status: ArtworkModerationStatus.pending,
            showIcon: false,
          ),
        ),
      ),
    );

    expect(find.text('Pending Review'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsNothing);
  });
}
