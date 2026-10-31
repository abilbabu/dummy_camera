import 'package:flutter_test/flutter_test.dart';
import 'package:capture_studio/services/paint_label_extractor.dart';

void main() {
  group('Paint Name, MRP, and Unit Price Pattern Extraction Tests', () {
    test('Image 5 Bucket: Extracts "TRA EML SUPWHITE", MRP ₹ 2230.00, Unit Price ₹ 223.00 / litre', () {
      final lines = [
        '10L NET',
        'Paints',
        'TRA EML SUPWHITE',
        'MRP ₹ 2230.00',
        'incl.of all taxes',
        'UNIT SALE PRICE',
        '₹ 223.00 PERLITRE',
        'Mfd 09/2026 EB2F',
        '(0057 0929 310) B.No. S1278',
        'ASIAN PAINTS LTD., REGD. OFFICE: 6A & 6B',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'TRA EML SUPWHITE');
      expect(data.mrp, '₹ 2230.00');
      expect(data.unitSalePrice, '₹ 223.00 / litre');
      expect(data.packQuantity, '10L NET');
      expect(data.mfd, '09/2026');
      expect(data.batchNo, 'S1278');
    });

    test('Image 3 Carton: Extracts "PGE LF BROWN", MRP ₹ 6360.00, Unit Price ₹ 397.50 / litre', () {
      final lines = [
        '4Nos. x 4L NET',
        'Paints',
        '0001 0415 240',
        'PGE',
        'LF BROWN',
        'K665',
        'MRP ₹ 6360.00 incl. of all taxes',
        'UNIT SALE PRICE ₹ 397.50 PER LITRE',
        'Mfd 08/2026',
        'ASIAN PAINTS LIMITED',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'PGE LF BROWN');
      expect(data.mrp, '₹ 6360.00');
      expect(data.unitSalePrice, '₹ 397.50 / litre');
      expect(data.packQuantity, '4Nos. x 4L NET');
      expect(data.mfd, '08/2026');
      expect(data.batchNo, 'K665');
    });

    test('Image 1 Carton: Extracts "PGE OX BLUE", MRP ₹ 6360.00, Unit Price ₹ 397.50 / litre', () {
      final lines = [
        'MRP ₹ 6360.00',
        'incl. of all taxes',
        'UNIT SALE PRICE ₹ 397.50 PER litre',
        '0001 0119 240',
        'PGE OX BLUE',
        'Mfd 02/2026 J222',
        'URB6',
        '4Nos. X 4L NET',
        'Paints',
        'MFD BY : PUNJAB PAINT COLOUR & VARNISH WORKS PVT. LTD.',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'PGE OX BLUE');
      expect(data.mrp, '₹ 6360.00');
      expect(data.unitSalePrice, '₹ 397.50 / litre');
      expect(data.packQuantity, '4Nos. X 4L NET');
      expect(data.mfd, '02/2026');
      expect(data.batchNo, 'URB6');
    });

    test('Image 2 Box: Extracts "PGE G BROWN", MRP ₹ 1728.00, Unit Price ₹ 0.43 / ml', () {
      final lines = [
        '8Nos. x 500ml NET',
        'Paints',
        'GA261',
        '0001 0413 150',
        'PGE',
        'G BROWN',
        'MRP ₹1728.00 incl. of all taxes',
        'UNIT SALE PRICE ₹0.43 PERml',
        'Mfd 08/2026',
        'ASIAN PAINTS LIMITED',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'PGE G BROWN');
      expect(data.mrp, '₹ 1728.00');
      expect(data.unitSalePrice, '₹ 0.43 / ml');
      expect(data.packQuantity, '8Nos. x 500ml NET');
      expect(data.mfd, '08/2026');
      expect(data.batchNo, 'GA261');
    });

    test('Image 2 Bottom Box: Extracts "PGE SM GRY-G", MRP ₹ 1728.00, Unit Price ₹ 0.43 / ml', () {
      final lines = [
        '8Nos. x 500ml NET',
        'Paints',
        'K3068',
        '0001 0616 150',
        'PGE',
        'SM GRY-G',
        'MRP ₹ 1728.00 incl. of all taxes',
        'UNIT SALE PRICE ₹ 0.43 PERml',
        'Mfd 08/2026',
        'ASIAN PAINTS LIMITED',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'PGE SM GRY-G');
      expect(data.mrp, '₹ 1728.00');
      expect(data.unitSalePrice, '₹ 0.43 / ml');
      expect(data.batchNo, 'K3068');
    });

    test('Image 2 Right Carton: Extracts "SNDSTN-G", MRP ₹ 2760.00, Unit Price ₹ 460.00 / litre', () {
      final lines = [
        'Nos. x 1L NET',
        'Paints',
        '0001 0333 210',
        'PGE SNDSTN-G',
        'MRP ₹ 2760.00 incl. of',
        'UNIT SALE PRICE ₹ 460.00',
        'Mfd 09/2026',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'PGE SNDSTN-G');
      expect(data.mrp, '₹ 2760.00');
      expect(data.unitSalePrice, '₹ 460.00 / litre');
      expect(data.mfd, '09/2026');
    });

    test('Image 4 Bucket: Extracts "APEX AB2", MRP ₹ 8510.00, Unit Price ₹ 425.50 / litre', () {
      final lines = [
        '20L NET',
        'Paints',
        'APEX AB2',
        'MRP ₹ 8510.00',
        'incl.of all taxes',
        'UNIT SALE PRICE',
        '₹ 425.50 PER LITRE',
        'Mfd 07/2026',
        '(0012 9097 320) B.No. M2282',
        'ASIAN PAINTS LTD.',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'APEX AB2');
      expect(data.mrp, '₹ 8510.00');
      expect(data.unitSalePrice, '₹ 425.50 / litre');
      expect(data.packQuantity, '20L NET');
      expect(data.mfd, '07/2026');
      expect(data.batchNo, 'M2282');
    });

    test('Stacked OCR lines: MRP on line 1, incl. taxes on line 2, amount on line 3', () {
      final lines = [
        '10L NET',
        'Paints',
        'APCOFRESH PURWHT',
        'MRP',
        'incl. of all taxes',
        '₹ 3450.00',
        'UNIT SALE PRICE',
        '345.00 PER LITRE',
        'Mfd: 04/2026',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'APCOFRESH PURWHT');
      expect(data.mrp, '₹ 3450.00');
      expect(data.unitSalePrice, '₹ 345.00 / litre');
      expect(data.mfd, '04/2026');
    });

    test('OCR currency symbol drops: MRP 6360.00 without Rupee symbol', () {
      final lines = [
        '4Nos. x 4L NET',
        'Paints',
        'SATIN EN BASE PAINT',
        'MRP: 1850.00',
        'incl.of all taxes',
        'UNIT SALE PRICE: 462.50 PER LITRE',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'SATIN EN BASE PAINT');
      expect(data.mrp, '₹ 1850.00');
      expect(data.unitSalePrice, '₹ 462.50 / litre');
    });

    test('OCR Rupee misread as asterisk (*) or F', () {
      final lines = [
        '20L NET',
        'PGE LF BROWN',
        'MRP * 8510.00',
        'incl. of all taxes',
        'UNIT SALE PRICE F 425.50 PER LITRE',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'PGE LF BROWN');
      expect(data.mrp, '₹ 8510.00');
      expect(data.unitSalePrice, '₹ 425.50 / litre');
    });

    test('Two-pack paint: Extracts Base and Hardener when present', () {
      final lines = [
        '4L NET',
        'WOODTECH PU PALLET',
        'MRP ₹ 4200.00',
        'UNIT SALE PRICE ₹ 1050.00 PER LITRE',
        'Mfd 05/2026',
        'BASE : 3.6 L',
        'HARDENER : 400 ml',
        'B.No. PU981',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'WOODTECH PU PALLET');
      expect(data.mrp, '₹ 4200.00');
      expect(data.unitSalePrice, '₹ 1050.00 / litre');
      expect(data.packQuantity, '4L NET');
      expect(data.mfd, '05/2026');
      expect(data.base, '3.6 L');
      expect(data.hardener, '400 ml');
      expect(data.batchNo, 'PU981');
    });

    test('Two-pack paint: Part A Base and Part B Hardener', () {
      final lines = [
        'EPOXY FLOOR COAT',
        'MRP ₹ 5800.00',
        'UNIT SALE PRICE ₹ 1160.00 PER LITRE',
        'PART A : BASE',
        'PART B : HARDENER',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.base, 'BASE');
      expect(data.hardener, 'HARDENER');
    });

    test('Base type classification: BASE WHITE or BASE 1', () {
      final lines = [
        '10L NET',
        'APEX ULTIMA',
        'BASE WHITE',
        'MRP ₹ 4850.00',
        'UNIT SALE PRICE ₹ 485.00 PER LITRE',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'APEX ULTIMA');
      expect(data.base, 'BASE WHITE');
      expect(data.hardener, isNull);
    });

    test('Real Image 1 Bucket 20L APEX AB2: Disjoint OCR blocks where MRP is in Block 1 and ₹ 8510.00 is in Block 2', () {
      final lines = [
        'Paints',
        'APEX',
        'MRP',
        'incl.of all taxes',
        'UNIT SALE PRICE',
        'Lead content does not exceed 90 ppm',
        'Mfd 07/2026',
        '(0012 9097 320) B.No. M2282',
        '20L NET',
        'AB2',
        '₹ 8510.00',
        '00441',
        '₹ 425.50 PER LITRE',
        '70K8WW4JS',
        'Base Paint,',
        'add colorants,',
        'colorants cost extra.',
        'Best before 60 months from Mfd',
        'ASIAN PAINTS LTD.',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'APEX AB2');
      expect(data.mrp, '₹ 8510.00');
      expect(data.unitSalePrice, '₹ 425.50 / litre');
      expect(data.packQuantity, '20L NET');
      expect(data.mfd, '07/2026');
      expect(data.batchNo, 'M2282');
      expect(data.base, 'Base Paint');
    });

    test('Real Image 2 Bucket 10L TRA EML SUPWHITE: Disjoint OCR blocks where MRP is separated from ₹ 2230.00', () {
      final lines = [
        'Paints',
        'TRA EML',
        'MRP',
        'incl.of all taxes',
        'UNIT SALE PRICE',
        'Lead content does not exceed 90 ppm',
        'Mfd 09/2026 EB2F',
        '(0057 0929 310) B.No. S1278',
        '10L NET',
        'SUPWHITE',
        '₹ 2230.00',
        '00393',
        '₹ 223.00 PER LITRE',
        '1nfEWlxUEB',
        'Best before 60 months from Mfd',
        'ASIAN PAINTS LTD.',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.paintName, 'TRA EML SUPWHITE');
      expect(data.mrp, '₹ 2230.00');
      expect(data.unitSalePrice, '₹ 223.00 / litre');
      expect(data.packQuantity, '10L NET');
      expect(data.mfd, '09/2026');
      expect(data.batchNo, 'S1278');
    });

    test('Image 1 with wide spacing and trailing AB2: "MRP   ₹ 8510.00 AB2"', () {
      final lines = [
        '20L NET',
        'APEX',
        'MRP   ₹ 8510.00 AB2',
        'incl.of all taxes',
        'UNIT SALE PRICE',
        '₹ 425.50 PER LITRE',
        'Mfd 07/2026',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.mrp, '₹ 8510.00');
      expect(data.unitSalePrice, '₹ 425.50 / litre');
    });

    test('Mathematical calculation fallback: extracts MRP even if MRP anchor is smudged', () {
      final lines = [
        '20L NET',
        'APEX AB2',
        'UNIT SALE PRICE',
        '₹ 425.50 PER LITRE',
        'Mfd 07/2026',
        '8510.00',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.mrp, '₹ 8510.00');
      expect(data.unitSalePrice, '₹ 425.50 / litre');
    });
  });

  group('Indian Paint Brand Extraction Tests', () {
    test('Birla Opus: Extracts brand "Birla Opus" and paint name "CALISTA EMULSION"', () {
      final lines = [
        'BIRLA OPUS',
        'CALISTA EMULSION',
        '10L NET',
        'MRP ₹ 3850.00',
        'UNIT SALE PRICE ₹ 385.00 PER LITRE',
        'Mfd 01/2026',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Birla Opus');
      expect(data.paintName, 'CALISTA EMULSION');
      expect(data.mrp, '₹ 3850.00');
    });

    test('Birla Opus with OPUS token alone', () {
      final lines = [
        'OPUS',
        'STYLE ACRYLIC GLOSS',
        '4L NET',
        'MRP ₹ 1420.00',
        'Mfd 02/2026',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Birla Opus');
      expect(data.paintName, 'STYLE ACRYLIC GLOSS');
      expect(data.mrp, '₹ 1420.00');
    });

    test('JSW Paints: Extracts brand "JSW Paints" and paint name "HALO INTERIOR"', () {
      final lines = [
        'JSW PAINTS',
        'HALO INTERIOR',
        '20L NET',
        'MRP ₹ 7200.00',
        'UNIT SALE PRICE ₹ 360.00 PER LITRE',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'JSW Paints');
      expect(data.paintName, 'HALO INTERIOR');
      expect(data.mrp, '₹ 7200.00');
    });

    test('British Paints (Berger subsidiary)', () {
      final lines = [
        'BRITISH PAINTS',
        'SHINGLE EXTERIOR EMULSION',
        '10L NET',
        'MRP ₹ 3200.00',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'British Paints');
      expect(data.mrp, '₹ 3200.00');
    });

    test('Sirca: Extracts Italian wood coating brand', () {
      final lines = [
        'SIRCA',
        'PU WOOD FINISH',
        '4L NET',
        'MRP ₹ 4800.00',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Sirca');
      expect(data.paintName, 'PU WOOD FINISH');
      expect(data.mrp, '₹ 4800.00');
    });

    test('Kamdhenu Paints', () {
      final lines = [
        'KAMDHENU PAINTS',
        'COLOUR DREAMZ WEATHERPROOF',
        '20L NET',
        'MRP ₹ 6100.00',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Kamdhenu Paints');
      expect(data.mrp, '₹ 6100.00');
    });

    test('Astral Paints', () {
      final lines = [
        'ASTRAL PAINTS',
        'ROYAL TOUCH EMULSION',
        '10L NET',
        'MRP ₹ 4400.00',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'Astral Paints');
      expect(data.mrp, '₹ 4400.00');
    });

    test('ICA Pidilite', () {
      final lines = [
        'ICA PIDILITE',
        'FINE WOOD COAT PU',
        '1L NET',
        'MRP ₹ 1150.00',
      ];

      final data = PaintLabelExtractor.extract(lines);
      expect(data.brandName, 'ICA Pidilite');
      expect(data.mrp, '₹ 1150.00');
    });
  });
}

