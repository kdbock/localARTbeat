import 'package:artbeat/src/integrations/capture_art_walk_hooks.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _RecordingSocialService extends Fake implements art_walk.SocialService {
  String? lastMessage;
  Map<String, dynamic>? lastMetadata;

  @override
  Future<void> postActivity({
    required String userId,
    required String userName,
    String? userAvatar,
    required art_walk.SocialActivityType type,
    required String message,
    Position? location,
    Map<String, dynamic>? metadata,
    bool respectAutoSharePreference = true,
  }) async {
    lastMessage = message;
    lastMetadata = metadata;
  }
}

void main() {
  group('CaptureArtWalkHooks postCaptureActivity', () {
    test(
      'uses outdoor artwork fallback copy and includes image metadata',
      () async {
        final social = _RecordingSocialService();
        final hooks = CaptureArtWalkHooks(socialService: social);
        final capture = CaptureModel(
          id: 'cap-1',
          userId: 'user-1',
          imageUrl: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          createdAt: DateTime(2026, 4, 7),
          title: '',
          locationName: '',
        );

        await hooks.postCaptureActivity(capture: capture, userName: 'Casey');

        expect(
          social.lastMessage,
          equals(
            'Casey discovered outdoor artwork in their area and got XP points',
          ),
        );
        expect(social.lastMetadata?['imageUrl'], capture.imageUrl);
        expect(social.lastMetadata?['photoUrl'], capture.imageUrl);
        expect(social.lastMetadata?['thumbnailUrl'], capture.thumbnailUrl);
        expect(
          (social.lastMetadata?['capture'] as Map)['thumbnailUrl'],
          capture.thumbnailUrl,
        );
      },
    );

    test('uses location name when available', () async {
      final social = _RecordingSocialService();
      final hooks = CaptureArtWalkHooks(socialService: social);
      final capture = CaptureModel(
        id: 'cap-2',
        userId: 'user-2',
        imageUrl: 'https://example.com/image2.jpg',
        createdAt: DateTime(2026, 4, 7),
        locationName: 'Downtown Arts District',
      );

      await hooks.postCaptureActivity(capture: capture, userName: 'Jordan');

      expect(
        social.lastMessage,
        equals(
          'Jordan discovered outdoor artwork in Downtown Arts District and got XP points',
        ),
      );
    });
  });
}
