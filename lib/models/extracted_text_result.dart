/// Model representing the text extracted from an image via on-device OCR.
class ExtractedTextResult {
  final String fullText;
  final List<String> lines;
  final String imagePath;
  final DateTime extractedAt;

  const ExtractedTextResult({
    required this.fullText,
    required this.lines,
    required this.imagePath,
    required this.extractedAt,
  });

  int get lineCount => lines.length;

  int get wordCount =>
      fullText.trim().isEmpty ? 0 : fullText.trim().split(RegExp(r'\s+')).length;

  int get charCount => fullText.length;

  bool get isEmpty => fullText.trim().isEmpty;
}
