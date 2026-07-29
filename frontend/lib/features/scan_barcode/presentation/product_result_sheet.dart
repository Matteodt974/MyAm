import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/nutriscore_badge.dart';
import 'nutrition_table.dart';
import '../../../shared/widgets/diet_banner.dart';
import '../../../shared/widgets/risk_level_style.dart';

import '../../profile_allergies/data/trusted_item_local_store.dart';
import '../../profile_allergies/presentation/trusted_item_controller.dart';
import '../../profile_allergies/presentation/diet_controller.dart';

import '../data/product_result.dart';

/// Fiche produit affichee en bottom sheet apres un scan code-barres reussi.
class ProductResultSheet extends ConsumerWidget {
  const ProductResultSheet({super.key, required this.product});

  final ProductResult product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDiets =
        ref.watch(dietControllerProvider).value ?? const <String>[];
    final trustedItems =
        ref.watch(trustedItemControllerProvider).value ?? const [];
    final isTrusted = trustedItems.any((item) => item.ean == product.ean);

    final matched = product.matchedAllergens;
    final isDanger = product.riskLevel == 'DANGER';
    final isWarning = product.riskLevel == 'WARNING';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NutriScoreBadge(grade: product.nutriscore),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name?.isNotEmpty == true
                            ? product.name!
                            : 'Produit sans nom',
                        style: theme.textTheme.titleLarge,
                      ),
                      if (product.brands?.isNotEmpty == true)
                        Text(
                          product.brands!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      Text(
                        'EAN ${product.ean}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isTrusted) ...[
              const _TrustedBadge(),
              const SizedBox(height: 12),
            ] else if (product.riskLevel == 'SAFE') ...[
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(trustedItemControllerProvider.notifier)
                          .add(
                            TrustedItem(
                              ean: product.ean,
                              name: product.name,
                              brands: product.brands,
                              nutriscore: product.nutriscore,
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
              ),
            ],
            const SizedBox(height: 16),
            if (isDanger) ...[
              _AllergyAlert(matched: matched, level: 'DANGER'),
              const SizedBox(height: 12),
            ],
            if (isWarning) ...[
              _AllergyAlert(
                matched: product.undeterminedAllergens.isNotEmpty
                    ? product.undeterminedAllergens
                    : product.tracesTags,
                level: 'WARNING',
              ),
              const SizedBox(height: 12),
            ],
            if (selectedDiets.isNotEmpty) ...[
              DietBanner(
                subject: 'Ce produit',
                isCompatible: product.dietCompatible,
                warningDietLabel: dietLabel(product.dietWarningDiet),
              ),
              const SizedBox(height: 12),
            ],
            _InfoRow(
              label: 'Groupe NOVA',
              value: product.novaGroup?.toString() ?? '—',
            ),
            const SizedBox(height: 12),
            if (product.nutriments != null) ...[
              NutritionTable(nutriments: product.nutriments!),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                'Données nutritionnelles non disponibles pour ce produit.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _TagsBlock(
              title: 'Allergènes',
              tags: product.allergensTags,
              emptyLabel: 'Aucun allergène listé.',
            ),
            const SizedBox(height: 12),
            _TagsBlock(
              title: 'Additifs',
              tags: product.additivesTags,
              emptyLabel: 'Aucun additif listé.',
            ),
            const SizedBox(height: 12),
            _TagsBlock(
              title: 'Labels',
              tags: product.labelTags,
              emptyLabel: 'Aucun label listé.',
            ),
            const SizedBox(height: 16),
            Text(
              'Score indicatif, ne remplace pas un avis nutritionniste.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
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

class _AllergyAlert extends StatelessWidget {
  const _AllergyAlert({required this.matched, required this.level});

  final List<String> matched;
  final String level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDanger = level == 'DANGER';
    final colors = RiskLevelColors.forLevel(theme.colorScheme, level);
    final bg = colors.background;
    final fg = colors.foreground;
    final message = isDanger
        ? 'Allergène présent : ${matched.join(', ')}'
        : 'Peut contenir : ${matched.join(', ')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock({
    required this.title,
    required this.tags,
    required this.emptyLabel,
  });

  final String title;

  final List<String> tags;

  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        if (tags.isEmpty)
          Text(
            emptyLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final tag in tags) _Tag(label: _label(tag))],
          ),
      ],
    );
  }

  static String _label(String tag) {
    final idx = tag.indexOf(':');

    return (idx >= 0 ? tag.substring(idx + 1) : tag).replaceAll('-', ' ');
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
