import 'package:flutter/material.dart';

import '../data/dish_result.dart';

class DishResultSheet extends StatelessWidget {
  const DishResultSheet({super.key, required this.result});

  final DishResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final unrecognized = result.status == 'unrecognized';

    final lowConfidence =
        result.status == 'low_confidence' ||
        ((result.confidence ?? 0) > 0 && (result.confidence ?? 0) < 0.70);

    final title = unrecognized
        ? 'Plat non reconnu'
        : lowConfidence
        ? 'Identification incertaine'
        : 'Plat identifié';

    return SafeArea(
      child: Padding(
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
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
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
                      Chip(label: Text(_withConfidence(c.name, c.confidence))),
                ],
              ),
            ],
            if (result.ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ingrédients probables', style: theme.textTheme.titleSmall),
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
                        ),
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
    );
  }

  static String _withConfidence(String label, double? confidence) {
    if (confidence == null) return label;
    return '$label ${(confidence * 100).round()} %';
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
