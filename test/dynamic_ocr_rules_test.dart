import 'package:flutter_test/flutter_test.dart';
import 'package:capture_studio/models/extraction_rules.dart';
import 'package:capture_studio/models/ocr_rule_model.dart';
import 'package:capture_studio/services/paint_label_extractor.dart';

void main() {
  group('Dynamic OCR Extraction Rules Tests', () {
    test('Default extraction rules contain factory paint brands and boilerplate', () {
      final defaults = ExtractionRules.defaults();
      expect(defaults.knownBrands.containsKey('ASIAN PAINTS'), isTrue);
      expect(defaults.knownBrands['ASIAN PAINTS'], 'Asian Paints');
      expect(defaults.knownSubBrands.containsKey('ROYALE'), isTrue);
      expect(defaults.brandAndBoilerplate.contains('LIMITED'), isTrue);
      expect(defaults.paintPrefixes.contains('PGE'), isTrue);
      expect(defaults.brandTokensToSkip.contains('BERGER'), isTrue);
    });

    test('Custom brand mapped dynamically is extracted from raw lines', () {
      final customRule = OcrRuleModel(
        category: 'brand',
        token: 'AURORA PAINTS',
        targetValue: 'Aurora Paints',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rules = ExtractionRules.fromRuleModels([customRule]);
      final lines = [
        'AURORA PAINTS LIMITED',
        'GLOSS ENAMEL',
        'MRP ₹ 1500.00',
        '4L NET',
      ];

      final result = PaintLabelExtractor.extract(lines, null, rules);
      expect(result.brandName, 'Aurora Paints');
      expect(result.mrp, '₹ 1500.00');
      expect(result.packQuantity, '4L NET');
    });

    test('Custom sub-brand mapped dynamically resolves both sub-brand and parent company', () {
      final subBrandRule = OcrRuleModel(
        category: 'sub_brand',
        token: 'NEOCOAT',
        targetValue: 'NeoCoat Ultima',
        parentBrand: 'Nippon Paint',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rules = ExtractionRules.fromRuleModels([subBrandRule]);
      final lines = [
        '10L NET',
        'NEOCOAT',
        'WHITE SHADE',
        'MRP ₹ 3400.00',
      ];

      final result = PaintLabelExtractor.extract(lines, null, rules);
      expect(result.brandName, 'Nippon Paint');
      expect(result.subBrand, 'NeoCoat Ultima');
    });

    test('Custom boilerplate rule dynamically filters out unwanted corporate strings', () {
      final customBoilerplate = OcrRuleModel(
        category: 'boilerplate',
        token: 'FOR EXPORT ONLY',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final customPrefix = OcrRuleModel(
        category: 'paint_prefix',
        token: 'ENAMEL',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rules = ExtractionRules.fromRuleModels([customBoilerplate, customPrefix]);
      final lines = [
        'FOR EXPORT ONLY',
        'ENAMEL GLOSS WHITE',
        'MRP ₹ 500.00',
      ];

      final result = PaintLabelExtractor.extract(lines, null, rules);
      expect(result.paintName, 'ENAMEL GLOSS WHITE');
      expect(result.paintName?.contains('FOR EXPORT'), isFalse);
    });

    test('Disabled dynamic rule is ignored during extraction', () {
      final disabledRule = OcrRuleModel(
        category: 'brand',
        token: 'TEMP BRAND',
        targetValue: 'Temp Brand',
        isActive: false, // Disabled!
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rules = ExtractionRules.fromRuleModels([disabledRule]);
      final lines = [
        'TEMP BRAND',
        'PREMIUM EMULSION',
        'MRP ₹ 999.00',
      ];

      final result = PaintLabelExtractor.extract(lines, null, rules);
      // Because the rule is inactive, it should NOT match
      expect(result.brandName, isNull);
    });
  });
}

