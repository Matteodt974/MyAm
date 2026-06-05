import 'package:flutter/material.dart';

/// Pastille Nutri-Score (A..E) avec le code couleur officiel.
///
/// Affiche un "?" gris si la note est absente (produit sans Nutri-Score dans OFF).
class NutriScoreBadge extends StatelessWidget {
  const NutriScoreBadge({super.key, required this.grade, this.size = 44});

  final String? grade;
  final double size;

  static const Map<String, Color> _colors = {
    'a': Color(0xFF038141),
    'b': Color(0xFF85BB2F),
    'c': Color(0xFFFECB02),
    'd': Color(0xFFEE8100),
    'e': Color(0xFFE63E11),
  };

  @override
  Widget build(BuildContext context) {
    final normalized = grade?.trim().toLowerCase();
    final color = _colors[normalized] ?? Colors.grey;
    final label = (normalized != null && _colors.containsKey(normalized))
        ? normalized.toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}
