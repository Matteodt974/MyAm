import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_result.freezed.dart';

part 'product_result.g.dart';

@freezed
abstract class ProductResult with _$ProductResult {
  const factory ProductResult({
    required String ean,
    String? name,
    String? brands,
    String? nutriscore,
    @JsonKey(name: 'nova_group') int? novaGroup,
    @JsonKey(name: 'additives_tags')
    @Default(<String>[])
    List<String> additivesTags,
    @JsonKey(name: 'allergens_tags')
    @Default(<String>[])
    List<String> allergensTags,
  }) = _ProductResult;

  factory ProductResult.fromJson(Map<String, dynamic> json) =>
      _$ProductResultFromJson(json);
}
