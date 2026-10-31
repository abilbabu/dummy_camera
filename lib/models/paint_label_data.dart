/// Model representing structured key-value data extracted specifically
/// from paint boxes, buckets, and cardboard covers (Amazon Textract style).
class PaintLabelData {
  final String? brandName;
  final String? subBrand;
  final String? paintName;
  final String? mrp;
  final String? unitSalePrice;
  final String? packQuantity;
  final String? mfd;
  final String? batchNo;
  final String? base;
  final String? hardener;
  final String rawText;
  final List<String> rawLines;

  const PaintLabelData({
    this.brandName,
    this.subBrand,
    this.paintName,
    this.mrp,
    this.unitSalePrice,
    this.packQuantity,
    this.mfd,
    this.batchNo,
    this.base,
    this.hardener,
    required this.rawText,
    this.rawLines = const [],
  });

  bool get hasAnyField =>
      brandName != null ||
      subBrand != null ||
      paintName != null ||
      mrp != null ||
      unitSalePrice != null ||
      packQuantity != null ||
      mfd != null ||
      batchNo != null ||
      base != null ||
      hardener != null;

  /// Returns structured key-value pairs for easy display & copying
  Map<String, String> get extractedFields {
    final Map<String, String> map = {};
    if (brandName != null && brandName!.isNotEmpty) {
      map['Brand'] = brandName!;
    }
    if (subBrand != null && subBrand!.isNotEmpty) {
      map['Sub-Brand'] = subBrand!;
    }
    if (mrp != null && mrp!.isNotEmpty) {
      map['MRP'] = mrp!;
    }
    if (unitSalePrice != null && unitSalePrice!.isNotEmpty) {
      map['Unit Sale Price'] = unitSalePrice!;
    }
    if (packQuantity != null && packQuantity!.isNotEmpty) {
      map['Net Quantity'] = packQuantity!;
    }
    if (mfd != null && mfd!.isNotEmpty) {
      map['Mfg Date (Mfd)'] = mfd!;
    }
    if (paintName != null && paintName!.isNotEmpty) {
      map['Paint Name'] = paintName!;
    }
    if (base != null && base!.isNotEmpty) {
      map['Base'] = base!;
    }
    if (hardener != null && hardener!.isNotEmpty) {
      map['Hardener'] = hardener!;
    }
    if (batchNo != null && batchNo!.isNotEmpty) {
      map['Batch No.'] = batchNo!;
    }
    return map;
  }

  /// Formatted summary of extracted fields
  String get formattedSummary {
    final buffer = StringBuffer();
    extractedFields.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}
