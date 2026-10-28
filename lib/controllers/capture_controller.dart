import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/captured_image.dart';
import '../services/camera_service.dart';
import '../services/local_image_storage_service.dart';

/// Controller managing image capture workflows, local gallery persistence,
/// and reactive state for the Capture Studio application.
class CaptureController extends ChangeNotifier {
  final CameraService _cameraService;
  final LocalImageStorageService _storageService;

  CaptureController({
    CameraService? cameraService,
    LocalImageStorageService? storageService,
  }) : _cameraService = cameraService ?? CameraService(),
       _storageService = storageService ?? LocalImageStorageService();

  // State properties
  List<CapturedImage> _images = [];
  bool _isLoading = true;
  bool _isCapturing = false;
  String? _errorMessage;

  // Getters
  List<CapturedImage> get images => List.unmodifiable(_images);
  bool get isLoading => _isLoading;
  bool get isCapturing => _isCapturing;
  String? get errorMessage => _errorMessage;
  int get totalCount => _images.length;
  bool get isEmpty => _images.isEmpty;
  bool get hasError => _errorMessage != null;

  /// Initialize controller, ensure storage is ready, and load saved images from SQLite
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _storageService.init();
      await loadImages();
    } catch (e) {
      _errorMessage = 'Failed to initialize image storage: $e';
      debugPrint('CaptureController.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload stored images from local database
  Future<void> loadImages() async {
    try {
      final savedImages = await _storageService.getAllImages();
      _images = savedImages;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load gallery images: $e';
      debugPrint('CaptureController.loadImages error: $e');
    }
    notifyListeners();
  }

  /// Execute camera capture workflow:
  /// 1. Prevents duplicate / rapid-tap capture invocations
  /// 2. Launches native camera interface
  /// 3. Saves captured image to dedicated persistent storage
  /// 4. Inserts new image into gallery at position 0 (directly after camera card)
  /// 5. Notifies UI listeners to immediately display thumbnail
  Future<bool> capturePhoto() async {
    // Prevent repeated capture requests while an operation is already in progress
    if (_isCapturing) {
      debugPrint(
        'Capture operation already in progress. Ignoring duplicate trigger.',
      );
      return false;
    }

    _isCapturing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final File? capturedFile = await _cameraService.capturePhoto();

      // User cancelled capture
      if (capturedFile == null) {
        _isCapturing = false;
        notifyListeners();
        return false;
      }

      // Persist captured file in application-managed directory and save metadata in SQLite
      final CapturedImage savedImage = await _storageService.saveCapturedFile(
        capturedFile,
      );

      // Avoid duplicate entries if the same event was fired
      final alreadyExists = _images.any((img) => img.id == savedImage.id);
      if (!alreadyExists) {
        // Place newly captured image at index 0 (immediately after camera card)
        _images.insert(0, savedImage);
      }

      _isCapturing = false;
      notifyListeners();
      return true;
    } on CameraCaptureException catch (e) {
      _errorMessage = e.message;
      _isCapturing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during photo capture: $e';
      _isCapturing = false;
      notifyListeners();
      return false;
    }
  }

  /// Safely delete an image from local storage and update gallery state.
  /// Validates database deletion before file removal.
  Future<bool> deleteImage(CapturedImage image) async {
    _errorMessage = null;

    try {
      final success = await _storageService.deleteImage(image);
      if (success) {
        _images.removeWhere((item) => item.id == image.id);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Could not find the image record to delete.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete photo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Dismiss active error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
