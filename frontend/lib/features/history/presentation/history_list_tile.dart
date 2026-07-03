import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/scan_history_entry.dart';

/// List tile displayed inside the scan history list.
class HistoryListTile extends StatelessWidget {
  const HistoryListTile({super.key, required this.entry, this.onTap});

  final ScanHistoryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDanger = entry.riskLevel == 'DANGER';

    final (chipBackground, chipForeground, chipLabel, chipIcon) =
        _riskChipTheme(colorScheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: _Thumbnail(entry: entry, showWarningOverlay: isDanger),
        title: Text(entry.title),
        subtitle: Text(
          DateFormat.yMd('fr_CA').add_Hm().format(entry.scannedAt),
        ),
        trailing: Chip(
          avatar: chipIcon != null
              ? Icon(chipIcon, size: 18, color: chipForeground)
              : null,
          label: Text(
            chipLabel,
            style: theme.textTheme.labelLarge?.copyWith(color: chipForeground),
          ),
          backgroundColor: chipBackground,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        onTap: onTap,
      ),
    );
  }

  /// Returns the visual theme for the risk level chip.
  (Color background, Color foreground, String label, IconData? icon)
  _riskChipTheme(ColorScheme colorScheme) {
    switch (entry.riskLevel) {
      case 'DANGER':
        return (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          'Danger',
          Icons.warning_amber_rounded,
        );
      case 'WARNING':
        return (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
          'Attention',
          null,
        );
      case 'SAFE':
        return (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
          'Sûr',
          null,
        );
      default:
        return (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
          '—',
          null,
        );
    }
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.entry, required this.showWarningOverlay});

  final ScanHistoryEntry entry;
  final bool showWarningOverlay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbnailPath = entry.thumbnailPath;

    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: thumbnailPath != null
              ? ClipOval(
                  child: Image.file(
                    File(thumbnailPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(_fallbackIcon(entry.type)),
                  ),
                )
              : Icon(_fallbackIcon(entry.type)),
        ),
        if (showWarningOverlay)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
              child: Icon(Icons.warning, size: 12, color: colorScheme.onError),
            ),
          ),
      ],
    );
  }

  static IconData _fallbackIcon(ScanType type) {
    switch (type) {
      case ScanType.barcode:
        return Icons.qr_code;
      case ScanType.dish:
        return Icons.restaurant;
      case ScanType.label:
        return Icons.label;
    }
  }
}
