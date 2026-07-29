/// UC-13 : niveau de severite associe a un allergene du profil.
///
/// Le cahier des charges impose trois niveaux, le plus haut correspondant a un
/// risque anaphylactique. Pour un sous-profil enfant, la severite par defaut est
/// [AllergySeverity.severe] (scenario alternatif 3b), modifiable par le parent.
enum AllergySeverity {
  light,
  moderate,
  severe;

  String get label => switch (this) {
    AllergySeverity.light => 'Légère',
    AllergySeverity.moderate => 'Modérée',
    AllergySeverity.severe => 'Sévère',
  };

  /// Precision affichee a cote du niveau le plus grave.
  String? get hint =>
      this == AllergySeverity.severe ? 'risque anaphylactique' : null;

  String get storageValue => name;

  static AllergySeverity fromStorage(Object? value) {
    return AllergySeverity.values.firstWhere(
      (severity) => severity.name == value,
      orElse: () => AllergySeverity.moderate,
    );
  }

  /// Severite appliquee a un allergene qui n'a pas encore ete configure.
  static AllergySeverity defaultFor({required bool isChildProfile}) =>
      isChildProfile ? AllergySeverity.severe : AllergySeverity.moderate;
}
