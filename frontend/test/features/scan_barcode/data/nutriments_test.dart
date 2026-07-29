import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/scan_barcode/data/nutriments.dart';
import 'package:myam/features/scan_barcode/data/product_result.dart';

void main() {
  group('Nutriments.fromJson', () {
    test('parse les valeurs pour 100 g', () {
      final nutriments = Nutriments.fromJson({
        'energy_kcal': 250.0,
        'fat': 18.2,
        'carbohydrates': 30,
        'proteins': 7.5,
        'salt': '1.8',
        'fiber': null,
      });

      expect(nutriments, isNotNull);
      expect(nutriments!.energyKcal, 250.0);
      expect(nutriments.fat, 18.2);
      expect(nutriments.carbohydrates, 30);
      expect(nutriments.salt, 1.8);
      expect(nutriments.fiber, isNull);
    });

    test('retourne null quand aucune valeur n\'est disponible', () {
      expect(Nutriments.fromJson(<String, dynamic>{}), isNull);
      expect(Nutriments.fromJson(null), isNull);
    });
  });

  test('ProductResult expose les nutriments du backend', () {
    final product = ProductResult.fromJson({
      'ean': '737628064502',
      'name': 'Produit test',
      'nutriments': {'energy_kcal': 120.0, 'salt': 0.4},
    });

    expect(product.nutriments, isNotNull);
    expect(product.nutriments!.energyKcal, 120.0);
    expect(product.nutriments!.salt, 0.4);
  });

  test('ProductResult tolere une fiche sans nutriments', () {
    final product = ProductResult.fromJson({'ean': '737628064502'});

    expect(product.nutriments, isNull);
  });
}
