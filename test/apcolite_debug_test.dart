import 'package:flutter_test/flutter_test.dart';
import 'package:capture_studio/services/paint_label_extractor.dart';

void main() {
  group('Real User Camera OCR Raw Text Tests', () {
    test('Image 1: SATIN raw OCR lines', () {
      final lines = [
        'ôpcolie,',
        'PREMIUM ENAMEL/',
        'ANTI',
        'W)FUNGAL',
        'SHIELD',
        'MRP',
        '1L NET',
        'evEARS',
        'WARRANTY*',
        'SOFT',
        'SHEEN +',
        'FINISH',
        'MFd 09/2026',
        'SATIN',
        ')HIGH',
        'COVERNGE',
        'STNBRON',
        'rom',
        'Best485.00',
        'before 60 months',
        'nc. of all taGpa',
        "Only for Base Paint, add colorrant's, colorsn",
        'PColitep',
        'PREMIuM ENAMEL',
      ];

      final data = PaintLabelExtractor.extract(lines);
      print('Image 1 -> Brand: [${data.brandName}], Sub-Brand: [${data.subBrand}], Paint: [${data.paintName}], MRP: [${data.mrp}], Qty: [${data.packQuantity}], Mfd: [${data.mfd}]');
      expect(data.brandName, 'Asian Paints');
      expect(data.subBrand, 'Apcolite');
      expect(data.paintName, contains('APCOLITE PREMIUM ENAMEL'));
      expect(data.mrp, '₹ 485.00');
    });

    test('Image 2: GLOSS raw OCR lines', () {
      final lines = [
        'oPcplile',
        'PREMI',
        'JM ENAMEL',
        'HIGH',
        'COVERAGE',
        '+',
        '1L NET',
        'WARRANTY*',
        'SUPERIOR',
        'HIDING',
        'D353',
        '+',
        '08/2026 BEST BEFORE 36 MNTHS FR',
        'HAP 460.00',
        'INL. CF AL TRES',
        'GLOSS',
        'STAIN',
        'GUARD',
        'Only for Base Paint add colorants, colorans',
      ];

      final data = PaintLabelExtractor.extract(lines);
      print('Image 2 -> Brand: [${data.brandName}], Sub-Brand: [${data.subBrand}], Paint: [${data.paintName}], MRP: [${data.mrp}], Qty: [${data.packQuantity}], Mfd: [${data.mfd}]');
      expect(data.brandName, 'Asian Paints');
      expect(data.subBrand, 'Apcolite');
      expect(data.paintName, contains('APCOLITE PREMIUM ENAMEL'));
      expect(data.mrp, '₹ 460.00');
    });

    test('Image 3: RUST SHIELD PU raw OCR lines', () {
      final lines = [
        'pcblite',
        'RUST SHIELD PU',
        'lo Primer for',
        'Metal Siurfaces',
        'ENA MEL',
        'YEARS',
        'WARRANTY*',
        'Quick',
        'Drying Time',
        'Non',
        'Yellowing',
        'FOR METAL AND WOODEN I SURFACES',
        '1L',
        'HET',
        'I1fd 082026',
        'RL IUOR',
        'MRP464.00 incl. Of all taxes',
        'Best Before 60 Tlorth from',
        'fd',
        'ior Base Paint, add colorants, Colorants ost exta',
      ];

      final data = PaintLabelExtractor.extract(lines);
      print('Image 3 -> Brand: [${data.brandName}], Sub-Brand: [${data.subBrand}], Paint: [${data.paintName}], MRP: [${data.mrp}], Qty: [${data.packQuantity}], Mfd: [${data.mfd}]');
      expect(data.brandName, 'Asian Paints');
      expect(data.subBrand, 'Apcolite');
      expect(data.paintName, contains('APCOLITE RUST SHIELD PU ENAMEL'));
      expect(data.mrp, '₹ 464.00');
    });

    test('Berger WeatherCoat Sub-brand resolution', () {
      final lines = [
        'WEATHERCOAT ALL GUARD',
        'EXTERIOR EMULSION',
        'MRP 3450.00',
        '10L NET',
      ];
      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Berger Paints');
      expect(data.subBrand, 'WeatherCoat');
      expect(data.paintName, contains('WEATHERCOAT ALL GUARD'));
    });

    test('Kansai Nerolac Impressions Sub-brand resolution', () {
      final lines = [
        'IMPRESSIONS KASHMIR',
        'LUXURY EMULSION',
        'MRP 4200.00',
        '4L NET',
      ];
      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Kansai Nerolac');
      expect(data.subBrand, 'Impressions');
      expect(data.paintName, contains('IMPRESSIONS KASHMIR'));
    });

    test('Dulux Velvet Touch Sub-brand resolution', () {
      final lines = [
        'VELVET TOUCH PEARL GLO',
        'MRP 2980.00',
        '4L NET',
      ];
      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Dulux');
      expect(data.subBrand, 'Velvet Touch');
      expect(data.paintName, contains('VELVET TOUCH PEARL GLO'));
    });

    test('Birla Opus Calista Sub-brand resolution', () {
      final lines = [
        'CALISTA PURE SPARKLE',
        'MRP 3100.00',
        '10L NET',
      ];
      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Birla Opus');
      expect(data.subBrand, 'Calista');
      expect(data.paintName, contains('CALISTA PURE SPARKLE'));
    });
  });
}
