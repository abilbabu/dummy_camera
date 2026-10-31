import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capture_studio/controllers/text_extractor_controller.dart';
import 'package:capture_studio/core/app_theme.dart';
import 'package:capture_studio/models/extracted_text_result.dart';
import 'package:capture_studio/views/text_extractor_screen.dart';

void main() {
  group('TextExtractorScreen Tests', () {
    testWidgets('Renders app title, Take Photo, and From Gallery buttons', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TextExtractorController>(
              create: (_) => TextExtractorController(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TextExtractorScreen(),
          ),
        ),
      );

      expect(find.text('Paint Label Extractor'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('From Gallery'), findsOneWidget);
      expect(find.text('Scan Paint Box or Label'), findsOneWidget);
    });

    testWidgets('Renders unified single card with MRP, USP, NET QTY, MFD, PAINT NAME, and conditional BASE & HARDENER', (tester) async {
      final controller = TextExtractorController();
      controller.setMockDataForTesting(
        paintName: 'TRA EML SUPWHITE',
        mrp: '₹ 2230.00',
        unitSalePrice: '₹ 223.00 / litre',
        packQuantity: '10L NET',
        mfd: '09/2026',
        base: 'BASE 1',
        hardener: '400 ml',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TextExtractorController>.value(
              value: controller,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TextExtractorScreen(),
          ),
        ),
      );

      // Verify all fields are present in the unified card
      expect(find.text('Extracted Paint Details'), findsOneWidget);
      expect(find.text('MRP'), findsOneWidget);
      expect(find.text('₹ 2230.00'), findsOneWidget);
      expect(find.text('UNIT SALE PRICE'), findsOneWidget);
      expect(find.text('₹ 223.00 / litre'), findsOneWidget);
      expect(find.text('NET QUANTITY'), findsOneWidget);
      expect(find.text('10L NET'), findsOneWidget);
      expect(find.text('MFD'), findsOneWidget);
      expect(find.text('09/2026'), findsOneWidget);
      expect(find.text('PAINT NAME'), findsOneWidget);
      expect(find.text('TRA EML SUPWHITE'), findsOneWidget);

      // Verify BASE and HARDENER are displayed because they exist
      expect(find.text('BASE'), findsOneWidget);
      expect(find.text('BASE 1'), findsOneWidget);
      expect(find.text('HARDENER'), findsOneWidget);
      expect(find.text('400 ml'), findsOneWidget);
    });

    test('ExtractedTextResult computes metrics accurately', () {
      final result = ExtractedTextResult(
        fullText: 'Invoice #1024\nTotal: \$540.00\nThank you for your business',
        lines: ['Invoice #1024', 'Total: \$540.00', 'Thank you for your business'],
        imagePath: '/path/to/test.jpg',
        extractedAt: DateTime.now(),
      );

      expect(result.lineCount, 3);
      expect(result.wordCount, 9);
      expect(result.isEmpty, isFalse);
    });
  });
}
