class ProductResult {
  const ProductResult({
    required this.ean,
    this.name,
    this.brands,
    this.nutriscore,
    this.novaGroup,
    this.additivesTags = const <String>[],
    this.allergensTags = const <String>[],
    this.tracesTags = const <String>[],
    this.ingredientsAnalysisTags = const <String>[],
    this.labelTags = const <String>[],
    this.dietCompatible = false,
    this.riskLevel,
    this.matchedAllergens = const <String>[],
    this.undeterminedAllergens = const <String>[],
  });

  final String ean;

  final String? name;

  final String? brands;

  final String? nutriscore;

  final int? novaGroup;

  final List<String> additivesTags;

  final List<String> allergensTags;

  final List<String> tracesTags;

  final List<String> ingredientsAnalysisTags;

  final List<String> labelTags;

  final bool dietCompatible;

  final String? riskLevel;

  final List<String> matchedAllergens;

  final List<String> undeterminedAllergens;

  factory ProductResult.fromJson(Map<String, dynamic> json) {
    return ProductResult(
      ean: json['ean']?.toString() ?? '',
      name: json['name']?.toString(),
      brands: json['brands']?.toString(),
      nutriscore: json['nutriscore']?.toString(),
      novaGroup: _toInt(json['nova_group']),
      additivesTags: _toStringList(json['additives_tags']),
      allergensTags: _toStringList(json['allergens_tags']),
      tracesTags: _toStringList(json['traces_tags']),
      ingredientsAnalysisTags: _toStringList(json['ingredients_analysis_tags']),
      labelTags: _toStringList(json['label_tags']),
      dietCompatible: json['diet_compatible'] as bool? ?? false,
      riskLevel: json['risk_level']?.toString(),
      matchedAllergens: _toStringList(json['matched_allergens']),
      undeterminedAllergens: _toStringList(json['undetermined_allergens']),
    );
  }

  static int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }

  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }
}
