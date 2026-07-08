import 'package:flutter/material.dart';

/// Maps a scan risk level ('DANGER' / 'WARNING' / anything else) to the
/// background/foreground color pair used across scan result screens
/// (product, dish, label sheets and the history list).
class RiskLevelColors {
  const RiskLevelColors({required this.background, required this.foreground});

  factory RiskLevelColors.forLevel(ColorScheme colorScheme, String? level) {
    switch (level) {
      case 'DANGER':
        return RiskLevelColors(
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
        );
      case 'WARNING':
        return RiskLevelColors(
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
        );
      default:
        return RiskLevelColors(
          background: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        );
    }
  }

  final Color background;
  final Color foreground;
}
