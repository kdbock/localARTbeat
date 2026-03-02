import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Connectivity,
])
class MockCameraPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements CameraPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Capture Sequence Tests', () {
    test('CaptureModel basic creation', () {
      final capture = CaptureModel(
        id: 'test_id',
        userId: 'test_user',
        imageUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now(),
        title: 'Test Capture',
        status: CaptureStatus.pending,
      );

      expect(capture.id, 'test_id');
      expect(capture.userId, 'test_user');
      expect(capture.title, 'Test Capture');
      expect(capture.status, CaptureStatus.pending);
    });

    test('CaptureModel fromJson/toJson', () {
      final now = DateTime.now();
      final json = {
        'id': 'test_id',
        'userId': 'test_user',
        'imageUrl': 'https://example.com/image.jpg',
        'createdAt': Timestamp.fromDate(now),
        'title': 'Test Capture',
        'status': 'pending',
      };

      final capture = CaptureModel.fromJson(json);
      expect(capture.id, 'test_id');
      expect(capture.userId, 'test_user');
      expect(capture.title, 'Test Capture');
      expect(capture.status, CaptureStatus.pending);

      final backToJson = capture.toJson();
      expect(backToJson['id'], isNull);
      expect(backToJson['userId'], 'test_user');
      expect(backToJson['status'], 'pending');
    });

    test('AdvancedCameraService initial state', () {
      final service = AdvancedCameraService();
      expect(service.isInitialized, isFalse);
      expect(service.flashMode, FlashMode.auto);
    });

    test('OfflineQueueItem model', () {
      final now = DateTime.now();
      final capture = CaptureModel(
        id: 'test_id',
        userId: 'test_user',
        imageUrl: '',
        createdAt: now,
        title: 'Test',
      );

      final item = OfflineQueueItem(
        id: 'q_123',
        localCaptureId: 'local_123',
        captureData: capture,
        localImagePath: '/tmp/image.jpg',
        status: OfflineQueueStatus.pending,
        retryCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.id, 'q_123');
      expect(item.localCaptureId, 'local_123');
      expect(item.localImagePath, '/tmp/image.jpg');
      expect(item.captureData.userId, 'test_user');
      expect(item.status, OfflineQueueStatus.pending);
    });
  });
}
