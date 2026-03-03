import 'dart:async';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeArtWalkService extends ArtWalkService {
  FakeArtWalkService(this._artPiecesFuture, {this.currentUserId = 'user-1'});

  final Future<List<PublicArtModel>> _artPiecesFuture;
  final String? currentUserId;
  int getArtInWalkCalls = 0;
  String? lastRequestedWalkId;

  @override
  Future<List<PublicArtModel>> getArtInWalk(String walkId) {
    getArtInWalkCalls += 1;
    lastRequestedWalkId = walkId;
    return _artPiecesFuture;
  }

  @override
  String? getCurrentUserId() => currentUserId;
}

class MockArtWalkProgressService extends Mock implements ArtWalkProgressService {}

class MockSocialService extends Mock implements SocialService {}

class MockArtWalkNavigationService extends Mock
    implements ArtWalkNavigationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ArtWalkModel buildWalk() => ArtWalkModel(
    id: 'walk-1',
    title: 'Test Walk',
    description: 'Test Description',
    userId: 'user-1',
    artworkIds: const ['art-1'],
    createdAt: DateTime(2026, 1, 1),
  );

  Widget buildHarness({
    required ArtWalkModel walk,
    required ArtWalkProgressService progressService,
    required AudioNavigationService audioService,
    required SocialService socialService,
    required ArtWalkNavigationService navigationService,
    ArtWalkService? providerArtWalkService,
    ArtWalkService? overrideArtWalkService,
  }) {
    return MultiProvider(
      providers: [
        if (providerArtWalkService != null)
          Provider<ArtWalkService>.value(value: providerArtWalkService),
        Provider<ArtWalkProgressService>.value(value: progressService),
        Provider<AudioNavigationService>.value(value: audioService),
        Provider<SocialService>.value(value: socialService),
        Provider<ArtWalkNavigationService>.value(value: navigationService),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: EnhancedArtWalkExperienceScreen(
          artWalkId: walk.id,
          artWalk: walk,
          artWalkService: overrideArtWalkService,
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'uses widget-level artWalkService override without requiring provider',
    (tester) async {
      final walk = buildWalk();
      final progressService = MockArtWalkProgressService();
      final audioService = AudioNavigationService();
      final socialService = MockSocialService();
      final navigationService = MockArtWalkNavigationService();
      final pendingArtPieces = Completer<List<PublicArtModel>>();
      final overrideService = FakeArtWalkService(pendingArtPieces.future);

      await tester.pumpWidget(
        buildHarness(
          walk: walk,
          overrideArtWalkService: overrideService,
          progressService: progressService,
          audioService: audioService,
          socialService: socialService,
          navigationService: navigationService,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
    },
  );

  testWidgets(
    'falls back to provider ArtWalkService when override is absent',
    (tester) async {
      final walk = buildWalk();
      final pendingArtPieces = Completer<List<PublicArtModel>>();
      final providerArtWalkService = FakeArtWalkService(pendingArtPieces.future);
      final progressService = MockArtWalkProgressService();
      final audioService = AudioNavigationService();
      final socialService = MockSocialService();
      final navigationService = MockArtWalkNavigationService();

      await tester.pumpWidget(
        buildHarness(
          walk: walk,
          providerArtWalkService: providerArtWalkService,
          progressService: progressService,
          audioService: audioService,
          socialService: socialService,
          navigationService: navigationService,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
    },
  );

  testWidgets(
    'throws when neither override nor provider ArtWalkService is supplied',
    (tester) async {
      final walk = buildWalk();
      final progressService = MockArtWalkProgressService();
      final audioService = AudioNavigationService();
      final socialService = MockSocialService();
      final navigationService = MockArtWalkNavigationService();

      await tester.pumpWidget(
        buildHarness(
          walk: walk,
          progressService: progressService,
          audioService: audioService,
          socialService: socialService,
          navigationService: navigationService,
        ),
      );
      final error = tester.takeException();
      expect(error, isA<ProviderNotFoundException>());
    },
  );
}
