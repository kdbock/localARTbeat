import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_capture/src/models/media_capture.dart';

void main() {
  group('MediaCapture', () {
    test('validity and type helpers reflect model values', () {
      final imageCapture = MediaCapture(
        id: 'm1',
        filePath: '/tmp/a.jpg',
        fileName: 'a.jpg',
        fileSize: 2048,
        mediaType: MediaType.image,
        captureSource: CaptureSource.camera,
        timestamp: DateTime.now(),
      );

      expect(imageCapture.isValid, isTrue);
      expect(imageCapture.isImage, isTrue);
      expect(imageCapture.isVideo, isFalse);
      expect(imageCapture.fileExtension, 'jpg');
      expect(imageCapture.formattedFileSize, '2.0 KB');
    });

    test('enum fromString fallbacks are stable', () {
      expect(MediaTypeExtension.fromString('MediaType.video'), MediaType.video);
      expect(MediaTypeExtension.fromString('invalid'), MediaType.image);
      expect(
        CaptureSourceExtension.fromString('invalid'),
        CaptureSource.camera,
      );
    });

    test('toJson/fromJson round-trip preserves fields', () {
      final capture = MediaCapture(
        id: 'm2',
        filePath: '/tmp/b.mp4',
        fileName: 'b.mp4',
        fileSize: 5000,
        mediaType: MediaType.video,
        captureSource: CaptureSource.camera,
        timestamp: DateTime.now(),
        metadata: const {'quality': 'high'},
      );

      final roundTrip = MediaCapture.fromJson(capture.toJson());
      expect(roundTrip.id, 'm2');
      expect(roundTrip.fileName, 'b.mp4');
      expect(roundTrip.mediaType, MediaType.video);
      expect(roundTrip.metadata?['quality'], 'high');
    });
  });
}
