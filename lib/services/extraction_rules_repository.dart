import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/extraction_rules.dart';
import '../models/ocr_rule_model.dart';
import 'database/database_helper.dart';

/// Repository managing OCR dictionary rules stored in SQLite
/// and keeping an in-memory cached `ExtractionRules` for high performance.
class ExtractionRulesRepository extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  ExtractionRulesRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  ExtractionRules _cachedRules = ExtractionRules.defaults();
  bool _isInitialized = false;

  ExtractionRules get cachedRules => _cachedRules;
  bool get isInitialized => _isInitialized;

  /// Initialize and load active rules from SQLite into memory cache
  Future<void> init() async {
    try {
      final activeModels = await _dbHelper.getActiveRules();
      if (activeModels.isNotEmpty) {
        _cachedRules = ExtractionRules.fromRuleModels(activeModels);
      } else {
        _cachedRules = ExtractionRules.defaults();
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ExtractionRulesRepository: $e');
      _cachedRules = ExtractionRules.defaults();
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Reload rules from DB into memory cache
  Future<void> refreshCache() async {
    final activeModels = await _dbHelper.getActiveRules();
    _cachedRules = ExtractionRules.fromRuleModels(activeModels);
    notifyListeners();
  }

  /// Get rules list optionally filtered by category
  Future<List<OcrRuleModel>> getRules({String? category}) async {
    return await _dbHelper.getAllRules(category: category);
  }

  /// Add a new custom OCR mapping rule
  Future<void> addRule({
    required String category,
    required String token,
    String? targetValue,
    String? parentBrand,
  }) async {
    final now = DateTime.now();
    final model = OcrRuleModel(
      category: category,
      token: token.trim().toUpperCase(),
      targetValue: targetValue?.trim(),
      parentBrand: parentBrand?.trim(),
      isCustom: true,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _dbHelper.insertRule(model);
    await refreshCache();
  }

  /// Update an existing rule
  Future<void> updateRule(OcrRuleModel rule) async {
    final updated = rule.copyWith(
      token: rule.token.trim().toUpperCase(),
      targetValue: rule.targetValue?.trim(),
      parentBrand: rule.parentBrand?.trim(),
      isCustom: true,
      updatedAt: DateTime.now(),
    );

    await _dbHelper.updateRule(updated);
    await refreshCache();
  }

  /// Delete a rule by its ID
  Future<void> deleteRule(int id) async {
    await _dbHelper.deleteRule(id);
    await refreshCache();
  }

  /// Toggle rule active/disabled state
  Future<void> toggleRuleActive(int id, bool isActive) async {
    await _dbHelper.toggleRuleActive(id, isActive);
    await refreshCache();
  }

  /// Reset all rules to factory defaults
  Future<void> resetToDefaults() async {
    await _dbHelper.resetToDefaults();
    await refreshCache();
  }

  /// Export all rules as a JSON string for backup/sharing across devices
  Future<String> exportRulesJson() async {
    final all = await _dbHelper.getAllRules();
    final list = all.map((r) => r.toMap()).toList();
    return jsonEncode(list);
  }

  /// Import rules from a JSON string
  Future<int> importRulesJson(String jsonStr) async {
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    int count = 0;
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final model = OcrRuleModel.fromMap(item);
        await _dbHelper.insertRule(model);
        count++;
      }
    }
    await refreshCache();
    return count;
  }
}

