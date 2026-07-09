class DishResult {
  const DishResult({
    this.filename,
    this.contentType,
    this.sizeBytes = 0,
    this.status = '',
    this.message = '',
    this.dishName,
    this.confidence,
    this.candidates = const <DishCandidate>[],
    this.ingredients = const <ProbableIngredient>[],
    this.foodDataMatches = const <FoodDataMatch>[],
    this.dietCompatible = false,
    this.dietStatus = 'unknown',
    this.dietWarningDiet,
  });

  final String? filename;
  final String? contentType;
  final int sizeBytes;
  final String status;
  final String message;
  final String? dishName;
  final double? confidence;
  final List<DishCandidate> candidates;
  final List<ProbableIngredient> ingredients;
  final List<FoodDataMatch> foodDataMatches;
  final bool dietCompatible;

  final String dietStatus;

  final String? dietWarningDiet;

  factory DishResult.fromJson(Map<String, dynamic> json) {
    return DishResult(
      filename: json['filename']?.toString(),
      contentType: json['content_type']?.toString(),
      sizeBytes: _toInt(json['size_bytes']) ?? 0,
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      dishName: json['dish_name']?.toString(),
      confidence: _toDouble(json['confidence']),
      candidates: _toList(json['candidates'], DishCandidate.fromJson),
      ingredients: _toList(json['ingredients'], ProbableIngredient.fromJson),
      foodDataMatches: _toList(
        json['food_data_matches'],
        FoodDataMatch.fromJson,
      ),
      dietCompatible: json['diet_compatible'] as bool? ?? false,
      dietStatus: json['diet_status']?.toString() ?? 'unknown',
      dietWarningDiet: json['diet_warning_diet']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      'status': status,
      'message': message,
      'dish_name': dishName,
      'confidence': confidence,
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
      'ingredients': ingredients
          .map((ingredient) => ingredient.toJson())
          .toList(),
      'food_data_matches': foodDataMatches
          .map((match) => match.toJson())
          .toList(),
      'diet_compatible': dietCompatible,
      'diet_status': dietStatus,
      'diet_warning_diet': dietWarningDiet,
    };
  }

  static int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) return double.tryParse(value);
    return null;
  }

  static List<T> _toList<T>(
    Object? value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) return <T>[];
    return value
        .whereType<Map>()
        .map((item) => fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}

class DishCandidate {
  const DishCandidate({this.name = '', this.confidence});

  final String name;
  final double? confidence;

  factory DishCandidate.fromJson(Map<String, dynamic> json) {
    return DishCandidate(
      name: json['name']?.toString() ?? '',
      confidence: DishResult._toDouble(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'confidence': confidence};
  }
}

class ProbableIngredient {
  const ProbableIngredient({this.name = '', this.confidence});

  final String name;
  final double? confidence;

  factory ProbableIngredient.fromJson(Map<String, dynamic> json) {
    return ProbableIngredient(
      name: json['name']?.toString() ?? '',
      confidence: DishResult._toDouble(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'confidence': confidence};
  }
}

Set<String> flaggedDishIngredients(
  List<ProbableIngredient> ingredients,
  List<String> allergies,
) {
  if (allergies.isEmpty) return const {};
  final flagged = <String>{};
  for (final ingredient in ingredients) {
    final name = ingredient.name.toLowerCase();
    for (final allergy in allergies) {
      final normalizedAllergy = allergy.toLowerCase();
      if (name.contains(normalizedAllergy) ||
          normalizedAllergy.contains(name)) {
        flagged.add(ingredient.name);
        break;
      }
    }
  }
  return flagged;
}

class FoodDataMatch {
  const FoodDataMatch({
    this.fdcId,
    this.description,
    this.dataType,
    this.brandOwner,
    this.ingredients,
  });

  final int? fdcId;
  final String? description;
  final String? dataType;
  final String? brandOwner;
  final String? ingredients;

  factory FoodDataMatch.fromJson(Map<String, dynamic> json) {
    return FoodDataMatch(
      fdcId: DishResult._toInt(json['fdc_id']),
      description: json['description']?.toString(),
      dataType: json['data_type']?.toString(),
      brandOwner: json['brand_owner']?.toString(),
      ingredients: json['ingredients']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fdc_id': fdcId,
      'description': description,
      'data_type': dataType,
      'brand_owner': brandOwner,
      'ingredients': ingredients,
    };
  }
}
