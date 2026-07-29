import 'package:freezed_annotation/freezed_annotation.dart';

part 'label_result.freezed.dart';
part 'label_result.g.dart';

@freezed
abstract class LabelResult with _$LabelResult {
  const factory LabelResult({
    @JsonKey(name: 'original_language') required String originalLanguage,
    @Default(false) bool translated,
    @JsonKey(name: 'translated_text') String? translatedText,
    @Default(<LabelIngredient>[]) List<LabelIngredient> ingredients,
    @JsonKey(name: 'risk_level') String? riskLevel,
    @JsonKey(name: 'matched_allergens')
    @Default(<String>[])
    List<String> matchedAllergens,
    @JsonKey(name: 'diet_compatible') @Default(false) bool dietCompatible,
    @JsonKey(name: 'diet_status') @Default('unknown') String dietStatus,
    @JsonKey(name: 'diet_warning_diet') String? dietWarningDiet,
  }) = _LabelResult;

  factory LabelResult.fromJson(Map<String, dynamic> json) =>
      _$LabelResultFromJson(json);
}

@freezed
abstract class LabelIngredient with _$LabelIngredient {
  const factory LabelIngredient({
    @Default('') String name,
    double? confidence,
  }) = _LabelIngredient;

  factory LabelIngredient.fromJson(Map<String, dynamic> json) =>
      _$LabelIngredientFromJson(json);
}
