import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../models/captured_image.dart';

/// Service responsible for persistent local image file management and SQLite metadata storage.
class LocalImageStorageService {
  static const String _tableName = 'captured_images';
  static const String _dbName = 'capture_studio.db';
  static const String _imageFolderName = 'capture_studio_images';

  Database? _database;
  String? _imagesDirectoryPath;
  final Uuid _uuid = const Uuid();

  bool get isInitialized => _database != null && _imagesDirectoryPath != null;

  /// Initialize database and dedicated storage folder
  Future<void> init() async {
    if (isInitialized) return;

    // Support Windows / Linux desktop environments and unit test runners
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 1. Prepare persistent storage directory
    final appDocsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDocsDir.path, _imageFolderName));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    _imagesDirectoryPath = imagesDir.path;

    // 2. Initialize SQLite Database
    final dbPath = p.join(appDocsDir.path, _dbName);
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            filePath TEXT NOT NULL,
            capturedAt INTEGER NOT NULL,
            fileSizeBytes INTEGER NOT NULL,
            width INTEGER,
            height INTEGER
          )
        ''');
      },
    );
  }

  /// Ensure service is initialized before running database operations
  Database get _db {
    if (_database == null) {
      throw StateError(
        'LocalImageStorageService has not been initialized. Call init() first.',
      );
    }
    return _database!;
  }

  /// Get the persistent images directory path
  String get imagesDirectoryPath {
    if (_imagesDirectoryPath == null) {
      throw StateError(
        'Images directory has not been resolved. Call init() first.',
      );
    }
    return _imagesDirectoryPath!;
  }

  /// Copy a newly captured temporary image file to application persistent storage
  /// and record its metadata in SQLite.
  ///
  /// Prevents temporary cache path retention and guarantees persistence.
  Future<CapturedImage> saveCapturedFile(File tempFile) async {
    if (!await tempFile.exists()) {
      throw FileSystemException(
        'Captured source file does not exist at temporary location.',
        tempFile.path,
      );
    }

    final fileSize = await tempFile.length();
    if (fileSize == 0) {
      throw const FileSystemException(
        'Captured image file is empty (0 bytes).',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final extension = p.extension(tempFile.path).isNotEmpty
        ? p.extension(tempFile.path)
        : '.jpg';
    final permanentFileName =
        'IMG_${now.millisecondsSinceEpoch}_${id.substring(0, 8)}$extension';
    final permanentFilePath = p.join(imagesDirectoryPath, permanentFileName);

    // 1. Copy temporary file to managed persistent directory
    final savedFile = await tempFile.copy(permanentFilePath);
    if (!await savedFile.exists()) {
      throw FileSystemException(
        'Failed to verify saved file in persistent storage directory.',
        permanentFilePath,
      );
    }

    // 2. Construct persistent metadata object
    final capturedImage = CapturedImage(
      id: id,
      filePath: savedFile.path,
      capturedAt: now,
      fileSizeBytes: fileSize,
    );

    // 3. Persist metadata into SQLite
    await _db.insert(
      _tableName,
      capturedImage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 4. Safely attempt to clean up original temp file if different
    if (tempFile.path != savedFile.path) {
      try {
        await tempFile.delete();
      } catch (_) {
        // Non-critical: OS will clean up temp cache eventually
      }
    }

    return capturedImage;
  }

  /// Fetch all stored image records, sorted by most recently captured first.
  /// Validates physical file existence and safely prunes orphaned records.
  Future<List<CapturedImage>> getAllImages() async {
    final rows = await _db.query(_tableName, orderBy: 'capturedAt DESC');

    final List<CapturedImage> validImages = [];
    final List<String> orphanedIds = [];

    for (final row in rows) {
      final img = CapturedImage.fromMap(row);
      if (img.exists) {
        validImages.add(img);
      } else {
        orphanedIds.add(img.id);
      }
    }

    // Clean up any database entries whose physical files were deleted externally
    if (orphanedIds.isNotEmpty) {
      await _db.delete(
        _tableName,
        where: 'id IN (${List.filled(orphanedIds.length, '?').join(',')})',
        whereArgs: orphanedIds,
      );
    }

    return validImages;
  }

  /// Safely delete an image.
  /// Rule: Never delete an image file before the metadata operation has been validated.
  Future<bool> deleteImage(CapturedImage image) async {
    // 1. First validate & remove metadata from database
    final rowsDeleted = await _db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [image.id],
    );

    // 2. Only if metadata record was successfully deleted from DB, delete the file
    if (rowsDeleted > 0) {
      final file = File(image.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint(
            'Warning: Could not delete physical file: ${image.filePath}. Error: $e',
          );
        }
      }
      return true;
    }

    return false;
  }

  /// Close database connection
  Future<void> dispose() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
