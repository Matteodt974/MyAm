import 'package:flutter/material.dart';

/// Themes clair et sombre de l'application (Material 3, teinte verte).
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF2E7D32);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      );
}
