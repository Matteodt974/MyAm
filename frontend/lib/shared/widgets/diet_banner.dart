import 'package:flutter/material.dart';

/// Bandeau de compatibilite avec les regimes selectionnes (UC-14).
///
/// Partage par les trois flux de scan : code-barres, plat et etiquette. Le
/// [subject] porte le nom de ce qui est analyse ("Ce produit", "Ce plat") pour
/// que le message reste naturel dans chaque contexte.
class DietBanner extends StatelessWidget {
  const DietBanner({
    super.key,
    required this.isCompatible,
    required this.subject,
    this.warningDietLabel,
  });

  final bool isCompatible;

  final String subject;

  final String? warningDietLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isCompatible
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final fg = isCompatible
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;
    final text = isCompatible
        ? '$subject respecte vos régimes sélectionnés.'
        : warningDietLabel == null
        ? '$subject ne respecte pas vos régimes sélectionnés.'
        : '$subject ne respecte pas votre régime '
              '${warningDietLabel!.toLowerCase()}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompatible ? Icons.verified_rounded : Icons.no_food_rounded,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau affiche quand le verdict de regime ne peut pas etre etabli.
class DietUncertainBanner extends StatelessWidget {
  const DietUncertainBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Traduit le nom technique d'un regime en libelle francais affichable.
String? dietLabel(String? value) {
  if (value == null) return null;
  switch (value) {
    case 'VEGAN':
      return 'vegan';
    case 'VEGETARIAN':
      return 'végétarien';
    case 'PESCETARIAN':
      return 'pescétarien';
    case 'HALAL':
      return 'halal';
    case 'KOSHER':
      return 'kasher';
    case 'GLUTEN_FREE':
      return 'sans gluten';
    case 'LACTOSE_FREE':
      return 'sans lactose';
    case 'OMNIVORE':
      return 'omnivore';
    default:
      return value.toLowerCase();
  }
}
