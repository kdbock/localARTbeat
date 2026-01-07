import 'package:artbeat_capture/src/utils/capture_helper.dart';

/// Enum for media types
enum MediaType { image, video }

/// Extension for MediaType enum
extension MediaTypeExtension on MediaType {
  static MediaType fromString(String value) {
    switch (value) {
      case 'MediaType.image':
        return MediaType.image;
      case 'MediaType.video':
        return MediaType.video;
      default:
        return MediaType.image;
    }
  }
}

/// Enum for capture sources
enum CaptureSource { camera }

/// Extension for CaptureSource enum
extension CaptureSourceExtension on CaptureSource {
  static CaptureSource fromString(String value) {
    switch (value) {
      case 'CaptureSource.camera':
        return CaptureSource.camera;
      default:
        return CaptureSource.camera;
    }
  }

  String get displayName {
    switch (this) {
      case CaptureSource.camera:
        return 'Camera';
    }
  }
}

/// Model for media capture data
class MediaCapture {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final MediaType mediaType;
  final CaptureSource captureSource;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  MediaCapture({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.mediaType,
    required this.captureSource,
    required this.timestamp,
    this.metadata,
  });

  /// Check if the capture data is valid
  bool get isValid {
    return id.isNotEmpty &&
        filePath.isNotEmpty &&
        fileName.isNotEmpty &&
        fileSize >= 0;
  }

  /// Check if this is an image capture
  bool get isImage => mediaType == MediaType.image;

  /// Check if this is a video capture
  bool get isVideo => mediaType == MediaType.video;

  /// Get file extension
  String get fileExtension => CaptureHelper.getFileExtension(fileName);

  /// Get formatted file size
  String get formattedFileSize => CaptureHelper.formatFileSize(fileSize);

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'fileName': fileName,
    'fileSize': fileSize,
    'mediaType': mediaType.toString(),
    'captureSource': captureSource.toString(),
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  /// Create from JSON
  factory MediaCapture.fromJson(Map<String, dynamic> json) => MediaCapture(
    id: json['id'] as String,
    filePath: json['filePath'] as String,
    fileName: json['fileName'] as String,
    fileSize: json['fileSize'] as int,
    mediaType: MediaTypeExtension.fromString(json['mediaType'] as String),
    captureSource: CaptureSourceExtension.fromString(
      json['captureSource'] as String,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}
