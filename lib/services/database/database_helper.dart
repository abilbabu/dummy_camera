import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/extraction_rules.dart';
import '../../models/ocr_rule_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String dbName = 'capture_studio_ocr.db';
  static const String tableOcrDictionary = 'ocr_dictionary';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // If running on desktop (Windows/Linux/macOS), initialize FFI
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableOcrDictionary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        token TEXT NOT NULL,
        target_value TEXT,
        parent_brand TEXT,
        is_custom INTEGER DEFAULT 1,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(category, token)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_ocr_dict_category ON $tableOcrDictionary(category, is_active)
    ''');

    // Seed default rules inside a batch transaction for speed
    final seedModels = DefaultExtractionRules.generateSeedModels();
    final batch = db.batch();
    for (final model in seedModels) {
      batch.insert(
        tableOcrDictionary,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // --- CRUD Operations ---

  Future<List<OcrRuleModel>> getAllRules({String? category}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (category != null && category.isNotEmpty) {
      maps = await db.query(
        tableOcrDictionary,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'token ASC',
      );
    } else {
      maps = await db.query(
        tableOcrDictionary,
        orderBy: 'category ASC, token ASC',
      );
    }
    return maps.map((m) => OcrRuleModel.fromMap(m)).toList();
  }

  Future<List<OcrRuleModel>> getActiveRules() async {
    final db = await database;
    final maps = await db.query(
      tableOcrDictionary,
      where: 'is_active = 1',
    );
    return maps.map((m) => OcrRuleModel.fromMap(m)).toList();
  }

  Future<int> insertRule(OcrRuleModel rule) async {
    final db = await database;
    return await db.insert(
      tableOcrDictionary,
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateRule(OcrRuleModel rule) async {
    final db = await database;
    if (rule.id == null) return 0;
    return await db.update(
      tableOcrDictionary,
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRule(int id) async {
    final db = await database;
    return await db.delete(
      tableOcrDictionary,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleRuleActive(int id, bool isActive) async {
    final db = await database;
    await db.update(
      tableOcrDictionary,
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reset to factory defaults by deleting custom rules and re-enabling default ones
  Future<void> resetToDefaults() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableOcrDictionary);

      final seedModels = DefaultExtractionRules.generateSeedModels();
      final batch = txn.batch();
      for (final model in seedModels) {
        batch.insert(
          tableOcrDictionary,
          model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

