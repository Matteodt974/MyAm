import 'package:flutter/material.dart';

/// Categorie clinique d'un type de l'echelle de Bristol.
///
/// Le decoupage suit celui du backend ([IntoleranceRuleEngine]) : 1-2
/// constipation, 3-5 normal, 6-7 diarrhee.
enum BristolCategory { constipation, normal, diarrhea }

/// Un des sept types de l'echelle de Bristol (UC-23).
class BristolType {
  const BristolType({
    required this.value,
    required this.label,
    required this.description,
    required this.category,
  });

  final int value;
  final String label;
  final String description;
  final BristolCategory category;
}

const List<BristolType> bristolTypes = <BristolType>[
  BristolType(
    value: 1,
    label: 'Type 1',
    description: 'Morceaux durs et séparés, comme des noix',
    category: BristolCategory.constipation,
  ),
  BristolType(
    value: 2,
    label: 'Type 2',
    description: 'En forme de saucisse, mais grumeleuse',
    category: BristolCategory.constipation,
  ),
  BristolType(
    value: 3,
    label: 'Type 3',
    description: 'En forme de saucisse, craquelée en surface',
    category: BristolCategory.normal,
  ),
  BristolType(
    value: 4,
    label: 'Type 4',
    description: 'En forme de saucisse, lisse et molle (idéal)',
    category: BristolCategory.normal,
  ),
  BristolType(
    value: 5,
    label: 'Type 5',
    description: 'Morceaux mous aux bords nets, évacués facilement',
    category: BristolCategory.normal,
  ),
  BristolType(
    value: 6,
    label: 'Type 6',
    description: 'Morceaux mous aux bords déchiquetés, pâteux',
    category: BristolCategory.diarrhea,
  ),
  BristolType(
    value: 7,
    label: 'Type 7',
    description: 'Entièrement liquide, aucun morceau solide',
    category: BristolCategory.diarrhea,
  ),
];

/// Renvoie le type correspondant a [value], ou null si hors de l'echelle.
BristolType? bristolTypeFor(int value) {
  for (final type in bristolTypes) {
    if (type.value == value) return type;
  }
  return null;
}

String bristolCategoryLabel(BristolCategory category) {
  switch (category) {
    case BristolCategory.constipation:
      return 'Constipation';
    case BristolCategory.normal:
      return 'Normal';
    case BristolCategory.diarrhea:
      return 'Diarrhée';
  }
}

/// Couleurs d'affichage d'une categorie, alignees sur [RiskLevelColors].
({Color background, Color foreground}) bristolCategoryColors(
  ColorScheme colorScheme,
  BristolCategory category,
) {
  switch (category) {
    case BristolCategory.constipation:
      return (
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      );
    case BristolCategory.normal:
      return (
        background: colorScheme.secondaryContainer,
        foreground: colorScheme.onSecondaryContainer,
      );
    case BristolCategory.diarrhea:
      return (
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      );
  }
}

/// Libelle FR du profil dominant renvoye par le backend (UC-26).
String dominantProfileLabel(String? profile) {
  switch (profile) {
    case 'CONSTIPATION':
      return 'Tendance à la constipation';
    case 'DIARRHEE':
      return 'Tendance à la diarrhée';
    case 'NORMAL':
      return 'Transit normal';
    case 'MIXTE':
      return 'Transit variable';
    default:
      return 'Profil indéterminé';
  }
}
