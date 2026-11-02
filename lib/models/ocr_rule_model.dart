enum OcrRuleCategory {
  brand('brand', 'Known Brand'),
  subBrand('sub_brand', 'Sub-Brand'),
  boilerplate('boilerplate', 'Boilerplate Filter'),
  paintPrefix('paint_prefix', 'Paint Prefix'),
  skipToken('skip_token', 'Brand Token to Skip');

  final String key;
  final String label;
  const OcrRuleCategory(this.key, this.label);

  static OcrRuleCategory fromKey(String key) {
    return OcrRuleCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => OcrRuleCategory.brand,
    );
  }
}

/// Represents an individual OCR extraction rule or mapping persisted in local DB.
class OcrRuleModel {
  final int? id;
  final String category; // 'brand', 'sub_brand', 'boilerplate', 'paint_prefix', 'skip_token'
  final String token; // Uppercase token to match against OCR
  final String? targetValue; // Canonical brand or sub-brand name
  final String? parentBrand; // For sub_brand: parent brand name
  final bool isCustom; // true = added/edited by user, false = factory default
  final bool isActive; // true = enabled, false = disabled
  final DateTime createdAt;
  final DateTime updatedAt;

  const OcrRuleModel({
    this.id,
    required this.category,
    required this.token,
    this.targetValue,
    this.parentBrand,
    this.isCustom = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  OcrRuleCategory get ruleCategory => OcrRuleCategory.fromKey(category);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'token': token.trim().toUpperCase(),
      'target_value': targetValue?.trim(),
      'parent_brand': parentBrand?.trim(),
      'is_custom': isCustom ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory OcrRuleModel.fromMap(Map<String, dynamic> map) {
    return OcrRuleModel(
      id: map['id'] as int?,
      category: map['category'] as String,
      token: (map['token'] as String).trim().toUpperCase(),
      targetValue: map['target_value'] as String?,
      parentBrand: map['parent_brand'] as String?,
      isCustom: (map['is_custom'] as int?) == 1,
      isActive: (map['is_active'] as int?) != 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  OcrRuleModel copyWith({
    int? id,
    String? category,
    String? token,
    String? targetValue,
    String? parentBrand,
    bool? isCustom,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OcrRuleModel(
      id: id ?? this.id,
      category: category ?? this.category,
      token: token ?? this.token,
      targetValue: targetValue ?? this.targetValue,
      parentBrand: parentBrand ?? this.parentBrand,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

