import 'package:flutter/material.dart';

import '../data/nutriments.dart';

/// UC-20 : tableau nutritionnel pour 100 g avec mise en evidence des valeurs
/// hors seuils.
///
/// Les seuils "eleve" reprennent les reperes front-of-pack de la Food Standards
/// Agency (par 100 g de solide) : matieres grasses > 17,5 g et sel > 1,5 g. Les
/// fibres sont mises en avant positivement a partir de 6 g, seuil de l'allegation
/// "riche en fibres" du reglement europeen 1924/2006. L'energie, les glucides et
/// les proteines n'ont pas de seuil grand public equivalent et restent neutres.
class NutritionTable extends StatelessWidget {
  const NutritionTable({super.key, required this.nutriments});

  final Nutriments nutriments;

  static const double _highFat = 17.5;
  static const double _highSalt = 1.5;
  static const double _highFiber = 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = <_NutrientRow>[
      _NutrientRow(
        label: 'Énergie',
        value: nutriments.energyKcal,
        unit: 'kcal',
      ),
      _NutrientRow(
        label: 'Matières grasses',
        value: nutriments.fat,
        unit: 'g',
        isHigh: (v) => v > _highFat,
        highNote: 'élevé',
      ),
      _NutrientRow(
        label: 'Glucides',
        value: nutriments.carbohydrates,
        unit: 'g',
      ),
      _NutrientRow(label: 'Protéines', value: nutriments.proteins, unit: 'g'),
      _NutrientRow(
        label: 'Sel',
        value: nutriments.salt,
        unit: 'g',
        isHigh: (v) => v > _highSalt,
        highNote: 'élevé',
      ),
      _NutrientRow(
        label: 'Fibres',
        value: nutriments.fiber,
        unit: 'g',
        isGood: (v) => v >= _highFiber,
        goodNote: 'riche en fibres',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_dining_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Nutrition', style: theme.textTheme.titleSmall),
            const SizedBox(width: 6),
            Text(
              'pour 100 g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [for (final row in rows) _NutrientTile(row: row)],
          ),
        ),
      ],
    );
  }
}

class _NutrientRow {
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.unit,
    this.isHigh,
    this.highNote,
    this.isGood,
    this.goodNote,
  });

  final String label;
  final double? value;
  final String unit;
  final bool Function(double)? isHigh;
  final String? highNote;
  final bool Function(double)? isGood;
  final String? goodNote;
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({required this.row});

  final _NutrientRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = row.value;

    final high = value != null && (row.isHigh?.call(value) ?? false);
    final good = value != null && (row.isGood?.call(value) ?? false);

    final color = high
        ? theme.colorScheme.error
        : good
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    final note = high ? row.highNote : (good ? row.goodNote : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(row.label, style: theme.textTheme.bodyMedium)),
          if (note != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: high
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: high
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            value == null ? '—' : '${_format(value)} ${row.unit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: value == null ? theme.colorScheme.outline : color,
              fontWeight: high || good ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(double value) {
    if (value >= 100) return value.round().toString();
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }
}
