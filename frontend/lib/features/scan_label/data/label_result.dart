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
