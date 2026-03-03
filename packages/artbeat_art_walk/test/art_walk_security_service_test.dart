import 'package:artbeat_art_walk/src/services/art_walk_security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArtWalkSecurityService', () {
    final service = ArtWalkSecurityService.instance;

    test('validateArtWalkInput sanitizes valid input', () async {
      final result = await service.validateArtWalkInput(
        title: '  <b>Downtown Tour</b>  ',
        description: 'See <i>public</i> murals',
        userId: 'user-1',
        tags: const ['murals', 'walking'],
        zipCode: '28204',
      );

      expect(result.isValid, isTrue);
      expect(result.sanitizedData?['title'], 'Downtown Tour');
      expect(result.sanitizedData?['description'], 'See public murals');
    });

    test('validateArtWalkInput rejects prohibited content', () async {
      final result = await service.validateArtWalkInput(
        title: 'Nice Walk',
        description: '<script>alert("xss")</script>',
        userId: 'user-2',
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, 'PROHIBITED_CONTENT');
    });

    test('validateArtWalkInput rejects invalid zip code', () async {
      final result = await service.validateArtWalkInput(
        title: 'Nice Walk',
        description: 'Safe content',
        userId: 'user-3',
        zipCode: 'ABCDE',
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, 'INVALID_ZIP_CODE');
    });

    test('validateCommentInput rejects spam content', () async {
      final result = await service.validateCommentInput(
        content: 'Buy now click here free money guaranteed',
        userId: 'user-4',
        artWalkId: 'walk-1',
      );

      expect(result.isValid, isFalse);
      expect(result.errorCode, 'SPAM_DETECTED');
    });

    test('generateSecureToken returns non-empty unique tokens', () {
      final tokenA = service.generateSecureToken();
      final tokenB = service.generateSecureToken();

      expect(tokenA, isNotEmpty);
      expect(tokenB, isNotEmpty);
      expect(tokenA, isNot(tokenB));
    });
  });
}
