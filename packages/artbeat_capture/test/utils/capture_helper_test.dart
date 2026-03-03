import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_capture/src/utils/capture_helper.dart';

void main() {
  group('CaptureHelper', () {
    test('validates file types by extension', () {
      expect(CaptureHelper.isValidImageType('artwork.JPG'), isTrue);
      expect(CaptureHelper.isValidImageType('clip.mp4'), isFalse);
      expect(CaptureHelper.isValidVideoType('clip.MOV'), isTrue);
      expect(CaptureHelper.isValidVideoType('notes.txt'), isFalse);
    });

    test('validates file size boundaries', () {
      expect(CaptureHelper.isValidFileSize(0), isTrue);
      expect(
        CaptureHelper.isValidFileSize(CaptureHelper.maxFileSizeBytes),
        isTrue,
      );
      expect(
        CaptureHelper.isValidFileSize(CaptureHelper.maxFileSizeBytes + 1),
        isFalse,
      );
      expect(CaptureHelper.isValidFileSize(-1), isFalse);
    });

    test('formats file size and extracts extension correctly', () {
      expect(CaptureHelper.formatFileSize(0), '0 B');
      expect(CaptureHelper.formatFileSize(999), '999 B');
      expect(CaptureHelper.formatFileSize(1024), '1.0 KB');
      expect(CaptureHelper.getFileExtension('piece.jpeg'), 'jpeg');
      expect(CaptureHelper.getFileExtension('no_extension'), '');
    });
  });
}
