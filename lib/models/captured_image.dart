import 'dart:io';
import 'package:intl/intl.dart';

/// Represents a persistent image captured via the camera and stored locally.
class CapturedImage {
  final String id;
  final String filePath;
  final DateTime capturedAt;
  final int fileSizeBytes;
  final int? width;
  final int? height;

  const CapturedImage({
    required this.id,
    required this.filePath,
    required this.capturedAt,
    required this.fileSizeBytes,
    this.width,
    this.height,
  });

  /// Check if the physical file exists on disk
  bool get exists => File(filePath).existsSync();

  /// Retrieve the Dart [File] handle
  File get file => File(filePath);

  /// Extract friendly file name
  String get fileName {
    final parts = filePath.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : 'photo.jpg';
  }

  /// Formatted date string, e.g. "Oct 28, 2026 • 10:24 AM"
  String get formattedDate {
    return DateFormat('MMM d, yyyy • h:mm a').format(capturedAt);
  }

  /// Short formatted date for small cards, e.g. "Oct 28, 10:24 AM"
  String get shortFormattedDate {
    final now = DateTime.now();
    final difference = now.difference(capturedAt);

    if (difference.inDays == 0 && now.day == capturedAt.day) {
      return 'Today, ${DateFormat('h:mm a').format(capturedAt)}';
    } else if (difference.inDays < 7) {
      return DateFormat('E, h:mm a').format(capturedAt);
    } else {
      return DateFormat('MMM d, h:mm a').format(capturedAt);
    }
  }

  /// Human-readable file size string, e.g. "2.4 MB" or "840 KB"
  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '0 B';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Convert model to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'capturedAt': capturedAt.millisecondsSinceEpoch,
      'fileSizeBytes': fileSizeBytes,
      'width': width,
      'height': height,
    };
  }

  /// Create model from SQLite map
  factory CapturedImage.fromMap(Map<String, dynamic> map) {
    return CapturedImage(
      id: map['id'] as String,
      filePath: map['filePath'] as String,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(map['capturedAt'] as int),
      fileSizeBytes: (map['fileSizeBytes'] as num).toInt(),
      width: map['width'] != null ? (map['width'] as num).toInt() : null,
      height: map['height'] != null ? (map['height'] as num).toInt() : null,
    );
  }

  CapturedImage copyWith({
    String? id,
    String? filePath,
    DateTime? capturedAt,
    int? fileSizeBytes,
    int? width,
    int? height,
  }) {
    return CapturedImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      capturedAt: capturedAt ?? this.capturedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapturedImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CapturedImage(id: $id, file: $filePath, date: $capturedAt, size: $fileSizeBytes)';
  }
}
