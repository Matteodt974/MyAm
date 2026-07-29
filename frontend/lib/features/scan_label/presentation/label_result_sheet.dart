import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/languages.dart';
import '../../../shared/widgets/diet_banner.dart';
import '../../profile_allergies/presentation/diet_controller.dart';
import '../data/label_result.dart';

/// Resultat d'analyse d'etiquette affiche en bottom sheet.
class LabelResultSheet extends ConsumerWidget {
  const LabelResultSheet({super.key, required this.result});

  final LabelResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final flagged = result.matchedAllergens.toSet();
    final diets = ref.watch(dietControllerProvider).value ?? const <String>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.document_scanner_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ingrédients analysés',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (result.translated) ...[
                Chip(
                  avatar: const Icon(Icons.translate, size: 18),
                  label: Text(
                    'Traduit depuis ${_translatedFrom(result.originalLanguage)}',
                  ),
                ),
                const SizedBox(height: 12),
                if (result.translatedText != null &&
                    result.translatedText!.isNotEmpty) ...[
                  _TranslationBlock(text: result.translatedText!),
                  const SizedBox(height: 16),
                ],
              ],
              if (result.ingredients.isEmpty)
                Text(
                  'Aucun ingrédient détecté.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                )
              else ...[
                if (flagged.isNotEmpty) ...[
                  _AllergyBanner(flagged: flagged),
                  const SizedBox(height: 12),
                ],
                if (diets.isNotEmpty) ...[
                  if (result.dietStatus == 'unknown')
                    const DietUncertainBanner(
                      text:
                          'Ingrédients insuffisants pour conclure sur vos '
                          'régimes.',
                    )
                  else
                    DietBanner(
                      subject: 'Ce produit',
                      isCompatible: result.dietStatus == 'compatible',
                      warningDietLabel: dietLabel(result.dietWarningDiet),
                    ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final ingredient in result.ingredients)
                      if (ingredient.name.isNotEmpty)
                        Chip(
                          label: Text(
                            _withConfidence(
                              ingredient.name,
                              ingredient.confidence,
                            ),
                            style:
                                flagged.contains(ingredient.name.toLowerCase())
                                ? TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  )
                                : null,
                          ),
                          backgroundColor:
                              flagged.contains(ingredient.name.toLowerCase())
                              ? theme.colorScheme.errorContainer
                              : null,
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _withConfidence(String label, double? confidence) {
    if (confidence == null) return label;
    return '$label ${(confidence * 100).round()} %';
  }

  static String _translatedFrom(String code) {
    final label = languageLabel(code);
    if (label.isEmpty) return code;

    final first = label[0].toLowerCase();
    if (const {'a', 'e', 'i', 'o', 'u', 'h'}.contains(first)) {
      return "l'$label";
    }
    return 'le $label';
  }
}

class _TranslationBlock extends StatelessWidget {
  const _TranslationBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traduction',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergyBanner extends StatelessWidget {
  const _AllergyBanner({required this.flagged});

  final Set<String> flagged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 18,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Allergènes détectés : ${flagged.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
