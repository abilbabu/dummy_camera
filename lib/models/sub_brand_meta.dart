/// Metadata pairing a paint sub-brand/product line with its parent manufacturer brand.
class SubBrandMeta {
  final String parentBrand;
  final String subBrand;

  const SubBrandMeta(this.parentBrand, this.subBrand);

  Map<String, dynamic> toMap() => {
        'parentBrand': parentBrand,
        'subBrand': subBrand,
      };

  factory SubBrandMeta.fromMap(Map<String, dynamic> map) => SubBrandMeta(
        map['parentBrand'] as String? ?? '',
        map['subBrand'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubBrandMeta &&
          runtimeType == other.runtimeType &&
          parentBrand == other.parentBrand &&
          subBrand == other.subBrand;

  @override
  int get hashCode => parentBrand.hashCode ^ subBrand.hashCode;

  @override
  String toString() => '$subBrand ($parentBrand)';
}

