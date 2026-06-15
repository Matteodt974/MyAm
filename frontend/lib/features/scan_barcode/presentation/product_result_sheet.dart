import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/nutriscore_badge.dart';
import '../../profile_allergies/presentation/allergy_controller.dart';
import '../data/product_result.dart';

/// Fiche produit affichee en bottom sheet apres un scan code-barres reussi.
///
/// Croise les `allergens_tags` du produit avec les allergies locales de
/// l'utilisateur pour mettre en evidence les correspondances (intersection simple).
class ProductResultSheet extends ConsumerWidget {
  const ProductResultSheet({super.key, required this.product});

  final ProductResult product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final matched = product.matchedAllergens;
    final isUnsafe = product.riskLevel == 'DANGER';

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
            const SizedBox(height: 16),
            if (isUnsafe) ...[
              _AllergyAlert(matched: matched),
              const SizedBox(height: 12),
            ],
            _InfoRow(
              label: 'Groupe NOVA',
              value: product.novaGroup?.toString() ?? '—',
            ),
            const SizedBox(height: 12),
            _TagsBlock(
              title: 'Allergènes',
              tags: product.allergensTags,
              highlight: userAllergies,
              emptyLabel: 'Aucun allergène listé.',
            ),
            const SizedBox(height: 12),
            _TagsBlock(
              title: 'Additifs',
              tags: product.additivesTags,
              emptyLabel: 'Aucun additif listé.',
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

  static List<String> _matchedAllergens(
    List<String> tags,
    List<String> userAllergies,
  ) {
    if (userAllergies.isEmpty) return const [];
    final result = <String>[];
    for (final tag in tags) {
      final normalized = _normalizeTag(tag);
      for (final allergy in userAllergies) {
        if (normalized.contains(allergy) || allergy.contains(normalized)) {
          result.add(normalized);
          break;
        }
      }
    }
    return result;
  }

  static String _normalizeTag(String tag) {
    // OFF renvoie "en:milk", "fr:lait"… on retire le prefixe de langue.
    final idx = tag.indexOf(':');
    final value = idx >= 0 ? tag.substring(idx + 1) : tag;
    return value.replaceAll('-', ' ').toLowerCase().trim();
  }
}

class _AllergyAlert extends StatelessWidget {
  const _AllergyAlert({required this.matched});

  final List<String> matched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Allergène présent dans votre profil : ${matched.join(', ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
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
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock({
    required this.title,
    required this.tags,
    required this.emptyLabel,
    this.highlight = const [],
  });

  final String title;
  final List<String> tags;
  final String emptyLabel;
  final List<String> highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (tags.isEmpty)
          Text(emptyLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                _Tag(
                  label: _label(tag),
                  danger: _isHighlighted(tag),
                ),
            ],
          ),
      ],
    );
  }

  bool _isHighlighted(String tag) {
    if (highlight.isEmpty) return false;
    final normalized = ProductResultSheet._normalizeTag(tag);
    return highlight
        .any((a) => normalized.contains(a) || a.contains(normalized));
  }

  static String _label(String tag) {
    final idx = tag.indexOf(':');
    return (idx >= 0 ? tag.substring(idx + 1) : tag).replaceAll('-', ' ');
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.danger = false});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = danger
        ? theme.colorScheme.error
        : theme.colorScheme.surfaceContainerHighest;
    final fg =
        danger ? theme.colorScheme.onError : theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
