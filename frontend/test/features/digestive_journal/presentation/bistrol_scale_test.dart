import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/digestive_journal/presentation/bristol_scale.dart';

void main() {
  group('bristolTypeFor', () {
    test('returns correct BristolType for valid values 1 to 7', () {
      expect(bristolTypeFor(1)?.category, equals(BristolCategory.constipation));
      expect(bristolTypeFor(4)?.category, equals(BristolCategory.normal));
      expect(bristolTypeFor(4)?.label, equals('Type 4'));
      expect(bristolTypeFor(7)?.category, equals(BristolCategory.diarrhea));
    });

    test('returns null when value is out of bounds', () {
      expect(bristolTypeFor(0), isNull);
      expect(bristolTypeFor(8), isNull);
      expect(bristolTypeFor(-1), isNull);
    });
  });

  group('bristolCategoryLabel', () {
    test('returns correct french labels for each category', () {
      expect(
        bristolCategoryLabel(BristolCategory.constipation),
        equals('Constipation'),
      );
      expect(bristolCategoryLabel(BristolCategory.normal), equals('Normal'));
      expect(
        bristolCategoryLabel(BristolCategory.diarrhea),
        equals('Diarrhée'),
      );
    });
  });

  group('bristolCategoryColors', () {
    test('returns correct color pair from ColorScheme for each category', () {
      const colorScheme = ColorScheme.light(
        tertiaryContainer: Colors.blue,
        onTertiaryContainer: Colors.white,
        secondaryContainer: Colors.green,
        onSecondaryContainer: Colors.black,
        errorContainer: Colors.red,
        onErrorContainer: Colors.yellow,
      );

      final constipationColors = bristolCategoryColors(
        colorScheme,
        BristolCategory.constipation,
      );
      expect(constipationColors.background, equals(Colors.blue));
      expect(constipationColors.foreground, equals(Colors.white));

      final normalColors = bristolCategoryColors(
        colorScheme,
        BristolCategory.normal,
      );
      expect(normalColors.background, equals(Colors.green));
      expect(normalColors.foreground, equals(Colors.black));

      final diarrheaColors = bristolCategoryColors(
        colorScheme,
        BristolCategory.diarrhea,
      );
      expect(diarrheaColors.background, equals(Colors.red));
      expect(diarrheaColors.foreground, equals(Colors.yellow));
    });
  });

  group('dominantProfileLabel', () {
    test('returns correct french label for known profile strings', () {
      expect(
        dominantProfileLabel('CONSTIPATION'),
        equals('Tendance à la constipation'),
      );
      expect(
        dominantProfileLabel('DIARRHEE'),
        equals('Tendance à la diarrhée'),
      );
      expect(dominantProfileLabel('NORMAL'), equals('Transit normal'));
      expect(dominantProfileLabel('MIXTE'), equals('Transit variable'));
    });

    test('returns default label for null or unknown profile strings', () {
      expect(dominantProfileLabel(null), equals('Profil indéterminé'));
      expect(dominantProfileLabel('UNKNOWN'), equals('Profil indéterminé'));
      expect(dominantProfileLabel(''), equals('Profil indéterminé'));
    });
  });
}