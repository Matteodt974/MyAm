/// UC-20 : profil nutritionnel d'un produit, pour 100 g / 100 ml.
///
/// Chaque valeur est nullable : Open Food Facts ne renseigne pas toujours la
/// fiche complete, et afficher 0 a la place d'une valeur absente serait
/// trompeur pour une personne allergique ou suivant un regime.
class Nutriments {
  const Nutriments({
    this.energyKcal,
    this.fat,
    this.carbohydrates,
    this.proteins,
    this.salt,
    this.fiber,
  });

  final double? energyKcal;
  final double? fat;
  final double? carbohydrates;
  final double? proteins;
  final double? salt;
  final double? fiber;

  bool get isEmpty =>
      energyKcal == null &&
      fat == null &&
      carbohydrates == null &&
      proteins == null &&
      salt == null &&
      fiber == null;

  static Nutriments? fromJson(Object? json) {
    if (json is! Map) return null;
    final parsed = Nutriments(
      energyKcal: _toDouble(json['energy_kcal']),
      fat: _toDouble(json['fat']),
      carbohydrates: _toDouble(json['carbohydrates']),
      proteins: _toDouble(json['proteins']),
      salt: _toDouble(json['salt']),
      fiber: _toDouble(json['fiber']),
    );
    return parsed.isEmpty ? null : parsed;
  }

  Map<String, dynamic> toJson() => {
    'energy_kcal': energyKcal,
    'fat': fat,
    'carbohydrates': carbohydrates,
    'proteins': proteins,
    'salt': salt,
    'fiber': fiber,
  };

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}
