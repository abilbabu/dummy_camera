import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:capture_studio/models/captured_image.dart';
import 'package:capture_studio/controllers/capture_controller.dart';
import 'package:capture_studio/services/camera_service.dart';
import 'package:capture_studio/services/local_image_storage_service.dart';

// Test doubles / mock implementations
class MockCameraService implements CameraService {
  File? fileToReturn;
  bool shouldThrow = false;
  int captureCalls = 0;

  @override
  Future<File?> capturePhoto() async {
    captureCalls++;
    if (shouldThrow) {
      throw CameraCaptureException('Camera error simulation');
    }
    return fileToReturn;
  }
}

class MockStorageService implements LocalImageStorageService {
  final List<CapturedImage> stored = [];
  bool initCalled = false;
  int deleteCalls = 0;

  @override
  bool get isInitialized => initCalled;

  @override
  String get imagesDirectoryPath => '/test/dir';

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<CapturedImage> saveCapturedFile(File tempFile) async {
    final image = CapturedImage(
      id: 'img_${stored.length + 1}',
      filePath: tempFile.path,
      capturedAt: DateTime(2026, 10, 28, 10, 30),
      fileSizeBytes: 2048576, // ~2.0 MB
    );
    stored.insert(0, image);
    return image;
  }

  @override
  Future<List<CapturedImage>> getAllImages() async {
    return List.from(stored);
  }

  @override
  Future<bool> deleteImage(CapturedImage image) async {
    deleteCalls++;
    return stored.remove(image);
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('CapturedImage Model Tests', () {
    test('Correctly serializes to and from Map', () {
      final capturedAt = DateTime(2026, 10, 28, 14, 15);
      final model = CapturedImage(
        id: 'test-uuid-1234',
        filePath: '/storage/emulated/0/capture_studio_images/photo1.jpg',
        capturedAt: capturedAt,
        fileSizeBytes: 1048576,
        width: 1920,
        height: 1080,
      );

      final map = model.toMap();
      expect(map['id'], 'test-uuid-1234');
      expect(
        map['filePath'],
        '/storage/emulated/0/capture_studio_images/photo1.jpg',
      );
      expect(map['capturedAt'], capturedAt.millisecondsSinceEpoch);
      expect(map['fileSizeBytes'], 1048576);
      expect(map['width'], 1920);
      expect(map['height'], 1080);

      final deserialized = CapturedImage.fromMap(map);
      expect(deserialized.id, model.id);
      expect(deserialized.filePath, model.filePath);
      expect(deserialized.capturedAt, model.capturedAt);
      expect(deserialized.fileSizeBytes, model.fileSizeBytes);
      expect(deserialized.width, model.width);
      expect(deserialized.height, model.height);
      expect(deserialized, equals(model));
    });

    test('Formats file size properly (Bytes, KB, MB)', () {
      final imgB = CapturedImage(
        id: '1',
        filePath: 'p.jpg',
        capturedAt: DateTime.now(),
        fileSizeBytes: 512,
      );
      expect(imgB.formattedFileSize, '512 B');

      final imgKB = CapturedImage(
        id: '2',
        filePath: 'p.jpg',
        capturedAt: DateTime.now(),
        fileSizeBytes: 350 * 1024,
      );
      expect(imgKB.formattedFileSize, '350.0 KB');

      final imgMB = CapturedImage(
        id: '3',
        filePath: 'p.jpg',
        capturedAt: DateTime.now(),
        fileSizeBytes: 3 * 1024 * 1024,
      );
      expect(imgMB.formattedFileSize, '3.0 MB');
    });
  });

  group('CaptureController Tests', () {
    late MockCameraService mockCamera;
    late MockStorageService mockStorage;
    late CaptureController controller;

    setUp(() {
      mockCamera = MockCameraService();
      mockStorage = MockStorageService();
      controller = CaptureController(
        cameraService: mockCamera,
        storageService: mockStorage,
      );
    });

    test('Initializes storage and starts in empty state', () async {
      expect(controller.isLoading, isTrue);
      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.isEmpty, isTrue);
      expect(controller.totalCount, 0);
      expect(mockStorage.initCalled, isTrue);
    });

    test(
      'Prevents concurrent capture invocations when capturing is active',
      () async {
        await controller.initialize();

        // Simulate a temp file returned by camera
        final tempFile = File('temp_photo.jpg');
        mockCamera.fileToReturn = tempFile;

        // Start first capture
        final future1 = controller.capturePhoto();

        // Attempt second capture while first is running
        final future2 = controller.capturePhoto();

        final results = await Future.wait([future1, future2]);

        // Exactly one operation succeeded, duplicate was blocked
        expect(results[0], isTrue);
        expect(results[1], isFalse);
        expect(mockCamera.captureCalls, 1);
        expect(controller.totalCount, 1);
      },
    );

    test(
      'Handles camera cancellation without errors or false entries',
      () async {
        await controller.initialize();
        mockCamera.fileToReturn = null; // User cancelled

        final success = await controller.capturePhoto();

        expect(success, isFalse);
        expect(controller.hasError, isFalse);
        expect(controller.totalCount, 0);
        expect(controller.isCapturing, isFalse);
      },
    );

    test('Inserts newest captured image at the start of gallery', () async {
      await controller.initialize();

      mockCamera.fileToReturn = File('photo1.jpg');
      await controller.capturePhoto();
      expect(controller.images.first.id, 'img_1');

      mockCamera.fileToReturn = File('photo2.jpg');
      await controller.capturePhoto();
      expect(controller.images.first.id, 'img_2');
      expect(controller.totalCount, 2);
    });

    test('Safely deletes photo and updates gallery state', () async {
      await controller.initialize();
      mockCamera.fileToReturn = File('photo1.jpg');
      await controller.capturePhoto();

      final imgToDelete = controller.images.first;
      final deleted = await controller.deleteImage(imgToDelete);

      expect(deleted, isTrue);
      expect(controller.totalCount, 0);
      expect(mockStorage.deleteCalls, 1);
    });
  });
}
