// Test léger de la barre de navigation animée (sans caméra ni réseau).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scan_app/shared/widgets/animated_bottom_nav.dart';

void main() {
  testWidgets('AnimatedBottomNav rend 3 onglets et notifie la sélection',
      (WidgetTester tester) async {
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

    // L'onglet central ("Scan") est toujours présent.
    expect(find.text('Scan'), findsOneWidget);

    // Taper le premier onglet déclenche le callback avec l'index 0.
    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();
    expect(tapped, 0);
  });
}
