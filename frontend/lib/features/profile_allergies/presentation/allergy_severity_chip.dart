import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/allergy_severity.dart';
import 'allergy_severity_controller.dart';

/// Puce d'allergene affichant sa severite (UC-13) et permettant de la changer.
class AllergySeverityChip extends ConsumerWidget {
  const AllergySeverityChip({
    super.key,
    required this.allergy,
    required this.onDeleted,
  });

  final String allergy;

  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Reconstruit la puce quand la table de severites change.
    ref.watch(allergySeverityControllerProvider);
    final severity = ref
        .read(allergySeverityControllerProvider.notifier)
        .severityOf(allergy);

    final colors = severityColors(theme.colorScheme, severity);

    return InputChip(
      backgroundColor: colors.background,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(allergy, style: TextStyle(color: colors.foreground)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colors.foreground.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              severity.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      onPressed: () => _pickSeverity(context, ref, severity),
      onDeleted: onDeleted,
      deleteIconColor: colors.foreground,
    );
  }

  Future<void> _pickSeverity(
    BuildContext context,
    WidgetRef ref,
    AllergySeverity current,
  ) async {
    final selected = await showModalBottomSheet<AllergySeverity>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Sévérité de « $allergy »',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final severity in AllergySeverity.values)
              ListTile(
                leading: Icon(
                  severity == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: severity == current
                      ? Theme.of(sheetContext).colorScheme.primary
                      : Theme.of(sheetContext).colorScheme.outline,
                ),
                title: Text(severity.label),
                subtitle: severity.hint == null ? null : Text(severity.hint!),
                onTap: () => Navigator.pop(sheetContext, severity),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null) return;

    await ref
        .read(allergySeverityControllerProvider.notifier)
        .setSeverity(allergy, selected);
  }
}

/// Couleurs de fond/texte associees a un niveau de severite.
({Color background, Color foreground}) severityColors(
  ColorScheme scheme,
  AllergySeverity severity,
) {
  return switch (severity) {
    AllergySeverity.severe => (
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    ),
    AllergySeverity.moderate => (
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
    ),
    AllergySeverity.light => (
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurfaceVariant,
    ),
  };
}
