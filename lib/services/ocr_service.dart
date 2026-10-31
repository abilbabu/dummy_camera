import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/extracted_text_result.dart';

/// 100% Free, on-device OCR service powered by Google ML Kit.
/// No API keys, no server costs, and completely offline.
class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Process an image file and extract all text blocks and lines.
  Future<ExtractedTextResult> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    final List<String> lines = [];
    final StringBuffer fullTextBuffer = StringBuffer();

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          lines.add(text);
          fullTextBuffer.writeln(text);
        }
      }
    }

    final fullText = fullTextBuffer.toString().trim();

    if (kDebugMode) {
      debugPrint('[OcrService] Extracted ${lines.length} lines from ${imageFile.path}');
    }

    return ExtractedTextResult(
      fullText: fullText,
      lines: lines,
      imagePath: imageFile.path,
      extractedAt: DateTime.now(),
    );
  }

  /// Dispose native recognizer resources when not needed
  Future<void> dispose() async {
    if (_textRecognizer != null) {
      await _textRecognizer!.close();
      _textRecognizer = null;
    }
  }
}
