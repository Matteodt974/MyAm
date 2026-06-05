import 'package:freezed_annotation/freezed_annotation.dart';

part 'dish_result.freezed.dart';
part 'dish_result.g.dart';

/// Resultat de `POST /v1/scan/dish` (UC5, stretch).
///
/// L'identification reelle du plat n'est pas encore branchee cote backend :
/// `status` vaut `not_implemented` et `candidates` est vide. Le modele est deja
/// pret a recevoir les vrais resultats (liste de plats candidats) plus tard.
@freezed
abstract class DishResult with _$DishResult {
  const factory DishResult({
    String? filename,
    @JsonKey(name: 'content_type') String? contentType,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
    @Default('') String status,
    @Default('') String message,
    @Default(<String>[]) List<String> candidates,
  }) = _DishResult;

  factory DishResult.fromJson(Map<String, dynamic> json) =>
      _$DishResultFromJson(json);
}
