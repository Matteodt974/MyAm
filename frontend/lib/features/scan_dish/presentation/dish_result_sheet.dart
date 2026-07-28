import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile_allergies/data/trusted_item_local_store.dart';
import '../../profile_allergies/presentation/allergy_controller.dart';
import '../../profile_allergies/presentation/diet_controller.dart';
import '../../profile_allergies/presentation/trusted_item_controller.dart';
import '../data/dish_result.dart';

class DishResultSheet extends ConsumerWidget {
  const DishResultSheet({super.key, required this.result});

  final DishResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allergies =
        ref.watch(allergyControllerProvider).asData?.value ?? const <String>[];
    final diets =
        ref.watch(dietControllerProvider).asData?.value ?? const <String>[];
    final trustedItems =
        ref.watch(trustedItemControllerProvider).value ?? const [];
    final trustedId = _trustedId(result);
    final isTrusted =
        trustedId != null && trustedItems.any((item) => item.id == trustedId);
    final flagged = flaggedDishIngredients(result.ingredients, allergies);

    final unrecognized = result.status == 'unrecognized';

    final lowConfidence =
        result.status == 'low_confidence' ||
        ((result.confidence ?? 0) > 0 && (result.confidence ?? 0) < 0.70);

    final dietState = result.dietStatus;
    final dietWarningLabel = _dietLabel(result.dietWarningDiet);
    final safeToTrust =
        !unrecognized && flagged.isEmpty && dietState != 'incompatible';

    final title = unrecognized
        ? 'Plat non reconnu'
        : lowConfidence
        ? 'Identification incertaine'
        : 'Plat identifié';

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
                    unrecognized
                        ? Icons.help_outline
                        : lowConfidence
                        ? Icons.warning_amber_rounded
                        : Icons.restaurant,
                    color: lowConfidence
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.message.isNotEmpty
                    ? result.message
                    : 'Aucun détail disponible pour cette analyse.',
                style: theme.textTheme.bodyMedium,
              ),
              if (result.dishName != null && result.dishName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(result.dishName!, style: theme.textTheme.headlineSmall),
              ],
              if (result.confidence != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Confiance : ${(result.confidence! * 100).round()} %',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              if (lowConfidence) ...[
                const SizedBox(height: 12),
                _Notice(
                  icon: Icons.warning_amber_rounded,
                  text:
                      'La photo ne permet pas une identification fiable. Reprenez une photo si nécessaire.',
                ),
              ],
              if (isTrusted) ...[
                const SizedBox(height: 12),
                const _TrustedBadge(),
              ] else if (trustedId != null && safeToTrust) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(trustedItemControllerProvider.notifier)
                        .add(
                          TrustedItem(
                            id: trustedId,
                            ean: trustedId,
                            name: result.dishName ?? result.message,
                          ),
                        );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ajouté aux items de confiance'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Ajouter aux items fiables'),
                ),
              ],
              if (result.candidates.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Candidats', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in result.candidates)
                      if (c.name.isNotEmpty)
                        Chip(
                          label: Text(_withConfidence(c.name, c.confidence)),
                        ),
                  ],
                ),
              ],
              if (result.ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Ingrédients probables',
                  style: theme.textTheme.titleSmall,
                ),
                if (flagged.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _AllergyBanner(flagged: flagged),
                ],
                const SizedBox(height: 8),
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
                            style: flagged.contains(ingredient.name)
                                ? TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  )
                                : null,
                          ),
                          backgroundColor: flagged.contains(ingredient.name)
                              ? theme.colorScheme.errorContainer
                              : null,
                        ),
                  ],
                ),
              ],
              if (result.foodDataMatches.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Références FoodData Central',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final match in result.foodDataMatches.take(4))
                  _FoodDataRow(match: match),
              ],
              if (diets.isNotEmpty) ...[
                const SizedBox(height: 16),
                if (dietState == 'unknown')
                  _DietUncertainBanner(
                    text: lowConfidence || unrecognized
                        ? 'Analyse photo insuffisante pour conclure sur vos régimes.'
                        : 'Le plat a été identifié, mais le verdict de régime reste incertain.',
                  )
                else
                  _DietBanner(
                    isCompatible: dietState == 'compatible',
                    warningDietLabel: dietWarningLabel,
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                'Fichier : ${result.filename ?? '—'} '
                '(${(result.sizeBytes / 1024).toStringAsFixed(0)} Ko)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
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

  static String? _trustedId(DishResult result) {
    final source = result.dishName?.trim().isNotEmpty == true
        ? result.dishName!.trim()
        : result.message.trim();

    if (source.isEmpty) return null;

    final slug = source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (slug.isEmpty) return null;
    return 'dish:$slug';
  }
}

class _TrustedBadge extends StatelessWidget {
  const _TrustedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Déjà vérifié : sûr pour votre profil',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietBanner extends StatelessWidget {
  const _DietBanner({required this.isCompatible, this.warningDietLabel});

  final bool isCompatible;

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
    final warningText = warningDietLabel == null
        ? 'Ce plat ne respecte pas vos régimes sélectionnés.'
        : 'Ce plat ne respecte pas votre régime ${warningDietLabel!.toLowerCase()}.';
    final text = isCompatible
        ? 'Ce plat respecte vos régimes sélectionnés.'
        : warningText;

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

class _DietUncertainBanner extends StatelessWidget {
  const _DietUncertainBanner({required this.text});

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

String? _dietLabel(String? value) {
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

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.tertiary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
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

class _FoodDataRow extends StatelessWidget {
  const _FoodDataRow({required this.match});

  final FoodDataMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (match.dataType != null && match.dataType!.isNotEmpty) match.dataType,
      if (match.brandOwner != null && match.brandOwner!.isNotEmpty)
        match.brandOwner,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.dataset_outlined,
            size: 18,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.description ?? 'Entrée FoodData Central'),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                if (match.ingredients != null && match.ingredients!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      match.ingredients!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
