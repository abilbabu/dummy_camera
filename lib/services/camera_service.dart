import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Custom exception for camera operation failures
class CameraCaptureException implements Exception {
  final String message;
  final String? code;

  CameraCaptureException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Service that interacts with the native camera via [ImagePicker]
class CameraService {
  final ImagePicker _picker;

  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Launch native camera to capture a new photo.
  /// Returns [File] of captured photo, or `null` if user cancelled.
  Future<File?> capturePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality:
            92, // High visual fidelity with reasonable storage efficiency
      );

      if (pickedFile == null) {
        // User cancelled camera capture without taking a photo
        return null;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        throw CameraCaptureException(
          'Camera output file was not found at specified path.',
        );
      }

      return file;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw CameraCaptureException(
          'Camera permission was denied. Please grant camera access in app settings.',
          code: e.code,
        );
      } else if (e.code == 'camera_access_restricted') {
        throw CameraCaptureException(
          'Camera access is restricted on this device.',
          code: e.code,
        );
      } else {
        throw CameraCaptureException(
          e.message ??
              'An error occurred while accessing the camera (${e.code}).',
          code: e.code,
        );
      }
    } catch (e) {
      if (e is CameraCaptureException) rethrow;
      throw CameraCaptureException('Unexpected camera capture error: $e');
    }
  }
}
