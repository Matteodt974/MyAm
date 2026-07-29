import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myam/features/digestive_journal/presentation/digestive_entry_sheet.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_CA'));

  testWidgets('save action remains visible above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showDigestiveEntrySheet(context),
                child: const Text('Ajouter'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final saveButton = find.text('Enregistrer');
    expect(saveButton, findsOneWidget);
    expect(tester.getBottomRight(saveButton).dy, lessThanOrEqualTo(420));
    expect(tester.takeException(), isNull);
  });
}
