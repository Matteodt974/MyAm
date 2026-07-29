import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myam/features/scan_dish/data/dish_result.dart';

import 'package:myam/features/scan_dish/presentation/dish_result_sheet.dart';

import 'package:myam/shared/widgets/animated_bottom_nav.dart';

void main() {
  testWidgets('AnimatedBottomNav rend 3 onglets et notifie la sélection', (
    WidgetTester tester,
  ) async {
    int tapped = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AnimatedBottomNav(
            currentIndex: 1,
            onTap: (i) => tapped = i,
          ),
        ),
      ),
    );

    expect(find.text('Scan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));

    await tester.pump();

    expect(tapped, 0);
  });

  test('DishResult parse la reponse UC7', () {
    final result = DishResult.fromJson({
      'filename': 'plat.jpg',
      'content_type': 'image/jpeg',
      'size_bytes': 123,
      'status': 'identified',
      'message': 'Plat identifie.',
      'dish_name': 'Salade grecque',
      'confidence': 0.91,
      'candidates': [
        {'name': 'Salade grecque', 'confidence': 0.91},
      ],
      'ingredients': [
        {'name': 'tomate', 'confidence': 0.84},
      ],
      'food_data_matches': [
        {
          'fdc_id': 170457,
          'description': 'Tomatoes, red, raw',
          'data_type': 'SR Legacy',
        },
      ],
    });

    expect(result.dishName, 'Salade grecque');
    expect(result.confidence, 0.91);
    expect(result.ingredients.single.name, 'tomate');
    expect(result.foodDataMatches.single.fdcId, 170457);
  });

  testWidgets('DishResultSheet affiche un plat identifié', (tester) async {
    await _pumpSheet(
      tester,
      const DishResult(
        status: 'identified',
        message: 'Plat identifie.',
        dishName: 'Salade grecque',
        confidence: 0.91,
        ingredients: [ProbableIngredient(name: 'tomate', confidence: 0.84)],
        foodDataMatches: [
          FoodDataMatch(
            description: 'Tomatoes, red, raw',
            dataType: 'SR Legacy',
          ),
        ],
      ),
    );

    expect(find.text('Plat identifié'), findsOneWidget);
    expect(find.text('Salade grecque'), findsOneWidget);
    expect(find.text('Ingrédients probables'), findsOneWidget);
    expect(find.text('tomate 84 %'), findsOneWidget);
    expect(find.text('Références FoodData Central'), findsOneWidget);
  });

  testWidgets('DishResultSheet affiche un avertissement basse confiance', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      const DishResult(
        status: 'low_confidence',
        message: 'Identification incertaine.',
        dishName: 'Ragout',
        confidence: 0.42,
      ),
    );

    expect(find.text('Identification incertaine'), findsOneWidget);
    expect(find.text('Confiance : 42 %'), findsOneWidget);
    // UC-08 : palier orange (30-50 %), avec pourcentage et source.
    expect(
      find.text('Identification très incertaine : 42 % de confiance'),
      findsOneWidget,
    );
    expect(find.textContaining('analyse visuelle (IA)'), findsOneWidget);
    expect(find.text('Demander confirmation au restaurant'), findsOneWidget);
  });

  testWidgets('DishResultSheet gradue l\'avertissement selon la confiance', (
    tester,
  ) async {
    // Palier jaune : 50-70 %.
    await _pumpSheet(
      tester,
      const DishResult(
        status: 'low_confidence',
        dishName: 'Ragout',
        confidence: 0.62,
      ),
    );
    expect(
      find.text('Identification peu fiable : 62 % de confiance'),
      findsOneWidget,
    );

    // Palier rouge : moins de 30 %.
    await _pumpSheet(
      tester,
      const DishResult(
        status: 'low_confidence',
        dishName: 'Ragout',
        confidence: 0.12,
      ),
    );
    expect(
      find.text('Identification non fiable : 12 % de confiance'),
      findsOneWidget,
    );
  });

  testWidgets('DishResultSheet masque l\'avertissement en haute confiance', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      const DishResult(
        status: 'identified',
        dishName: 'Salade grecque',
        confidence: 0.91,
      ),
    );

    expect(find.textContaining('de confiance'), findsNothing);
    expect(find.text('Demander confirmation au restaurant'), findsNothing);
  });

  testWidgets('DishResultSheet affiche un état non reconnu', (tester) async {
    await _pumpSheet(
      tester,
      const DishResult(
        status: 'unrecognized',
        message: 'Aucun plat identifiable.',
      ),
    );

    expect(find.text('Plat non reconnu'), findsOneWidget);
    expect(find.text('Aucun plat identifiable.'), findsOneWidget);
  });
}

Future<void> _pumpSheet(WidgetTester tester, DishResult result) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: DishResultSheet(result: result)),
      ),
    ),
  );
}
