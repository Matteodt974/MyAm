import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish_result.freezed.dart';

part 'dish_result.g.dart';

@freezed
abstract class DishResult with _$DishResult {
  const factory DishResult({
    String? filename,
    @JsonKey(name: 'content_type') String? contentType,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
    @Default('') String status,
    @Default('') String message,
    @JsonKey(name: 'dish_name') String? dishName,
    double? confidence,
    @Default(<DishCandidate>[]) List<DishCandidate> candidates,
    @Default(<ProbableIngredient>[]) List<ProbableIngredient> ingredients,
    @JsonKey(name: 'food_data_matches')
    @Default(<FoodDataMatch>[])
    List<FoodDataMatch> foodDataMatches,
  }) = _DishResult;

  factory DishResult.fromJson(Map<String, dynamic> json) =>
      _$DishResultFromJson(json);
}

@freezed
abstract class DishCandidate with _$DishCandidate {
  const factory DishCandidate({@Default('') String name, double? confidence}) =
      _DishCandidate;

  factory DishCandidate.fromJson(Map<String, dynamic> json) =>
      _$DishCandidateFromJson(json);
}

@freezed
abstract class ProbableIngredient with _$ProbableIngredient {
  const factory ProbableIngredient({
    @Default('') String name,
    double? confidence,
  }) = _ProbableIngredient;

  factory ProbableIngredient.fromJson(Map<String, dynamic> json) =>
      _$ProbableIngredientFromJson(json);
}

/// Returns the ingredient names from [ingredients] that match one of the
/// user's [allergies] (case-insensitive substring match in either
/// direction). Shared between the dish result UI and scan history so both
/// agree on what counts as a flagged ingredient.
Set<String> flaggedDishIngredients(
  List<ProbableIngredient> ingredients,
  List<String> allergies,
) {
  if (allergies.isEmpty) return const {};
  final flagged = <String>{};
  for (final ingredient in ingredients) {
    final name = ingredient.name.toLowerCase();
    for (final allergy in allergies) {
      if (name.contains(allergy) || allergy.contains(name)) {
        flagged.add(ingredient.name);
        break;
      }
    }
  }
  return flagged;
}

@freezed
abstract class FoodDataMatch with _$FoodDataMatch {
  const factory FoodDataMatch({
    @JsonKey(name: 'fdc_id') int? fdcId,
    String? description,
    @JsonKey(name: 'data_type') String? dataType,
    @JsonKey(name: 'brand_owner') String? brandOwner,
    String? ingredients,
  }) = _FoodDataMatch;

  factory FoodDataMatch.fromJson(Map<String, dynamic> json) =>
      _$FoodDataMatchFromJson(json);
}
