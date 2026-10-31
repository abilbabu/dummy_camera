import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/extracted_text_result.dart';
import '../models/paint_label_data.dart';
import '../services/ocr_service.dart';
import '../services/paint_label_extractor.dart';

/// State management controller for image picking, OCR text extraction,
/// and structured field parsing (Amazon Textract style for paint cartons & buckets).
class TextExtractorController extends ChangeNotifier {
  final OcrService _ocrService;
  final ImagePicker _picker;

  TextExtractorController({
    OcrService? ocrService,
    ImagePicker? picker,
  })  : _ocrService = ocrService ?? OcrService(),
        _picker = picker ?? ImagePicker();

  File? _imageFile;
  ExtractedTextResult? _extractedResult;
  PaintLabelData? _paintLabelData;
  bool _isProcessing = false;
  String? _errorMessage;

  // Getters
  File? get imageFile => _imageFile;
  ExtractedTextResult? get extractedResult => _extractedResult;
  PaintLabelData? get paintLabelData => _paintLabelData;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _extractedResult != null;
  String get text => _extractedResult?.fullText ?? '';

  /// Capture photo from Camera and extract text immediately
  Future<void> captureFromCamera() async {
    await _pickAndExtract(ImageSource.camera);
  }

  /// Pick image from Gallery and extract text immediately
  Future<void> pickFromGallery() async {
    await _pickAndExtract(ImageSource.gallery);
  }

  Future<void> _pickAndExtract(ImageSource source) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (picked == null) {
        _isProcessing = false;
        notifyListeners();
        return;
      }

      _imageFile = File(picked.path);
      notifyListeners();

      // 1. Run on-device OCR
      final result = await _ocrService.extractText(_imageFile!);
      _extractedResult = result;

      // 2. Parse structured fields (Paint Name, MRP, USP, Pack Qty, Mfd, Batch)
      _paintLabelData = PaintLabelExtractor.extract(result.lines, result.fullText);

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to extract text: $e';
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Allow user to edit the extracted text and re-parse structured fields
  void updateText(String newText) {
    if (_extractedResult != null) {
      final lines = newText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      _extractedResult = ExtractedTextResult(
        fullText: newText,
        lines: lines,
        imagePath: _extractedResult!.imagePath,
        extractedAt: _extractedResult!.extractedAt,
      );
      _paintLabelData = PaintLabelExtractor.extract(lines, newText);
      notifyListeners();
    }
  }

  /// Clear current image and extracted data
  void clear() {
    _imageFile = null;
    _extractedResult = null;
    _paintLabelData = null;
    _errorMessage = null;
    _isProcessing = false;
    notifyListeners();
  }

  /// Helper for unit/widget testing to supply mocked extracted data
  @visibleForTesting
  void setMockDataForTesting({
    String? paintName,
    String? mrp,
    String? unitSalePrice,
    String? packQuantity,
    String? mfd,
    String? batchNo,
    String? base,
    String? hardener,
  }) {
    _extractedResult = ExtractedTextResult(
      fullText: 'Mock paint data',
      lines: ['Mock paint data'],
      imagePath: '/mock/path.jpg',
      extractedAt: DateTime.now(),
    );
    _paintLabelData = PaintLabelData(
      paintName: paintName,
      mrp: mrp,
      unitSalePrice: unitSalePrice,
      packQuantity: packQuantity,
      mfd: mfd,
      batchNo: batchNo,
      base: base,
      hardener: hardener,
      rawText: 'Mock paint data',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
