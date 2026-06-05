import 'package:flutter/material.dart';

import '../data/dish_result.dart';

/// Affiche le resultat (ou le placeholder) de l'analyse photo de plat.
class DishResultSheet extends StatelessWidget {
  const DishResultSheet({super.key, required this.result});

  final DishResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notImplemented = result.status == 'not_implemented';

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
                  notImplemented ? Icons.hourglass_empty : Icons.restaurant,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notImplemented ? 'Photo bien reçue' : 'Plat identifié',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'Analyse en cours de développement.',
              style: theme.textTheme.bodyMedium,
            ),
            if (result.candidates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in result.candidates) Chip(label: Text(c)),
                ],
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
    );
  }
}
