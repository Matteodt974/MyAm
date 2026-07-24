import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/digestive_journal/data/consent_local_store.dart';
import 'package:myam/features/digestive_journal/presentation/consent_screen.dart';

class MockConsentLocalStore extends Mock implements ConsentLocalStore {}

/// Builds a test app wrapping [child] with a [ProviderScope] and [MaterialApp].
Widget createTestApp({
  required Widget child,
  required MockConsentLocalStore mockStore,
}) {
  return ProviderScope(
    overrides: [consentLocalStoreProvider.overrideWithValue(mockStore)],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockConsentLocalStore mockStore;

  setUp(() {
    mockStore = MockConsentLocalStore();
    when(() => mockStore.load()).thenAnswer((_) async => false);
  });

  group('ConsentScreen', () {
    testWidgets('renders title, icon, and explanation text', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showConsentDialog(context),
                child: const Text('Open'),
              );
            },
          ),
          mockStore: mockStore,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Avertissement de confidentialité'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(
        find.textContaining('données médicales sensibles'),
        findsOneWidget,
      );
    });

    testWidgets('"Refuser" button pops with false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showConsentDialog(context);
                },
                child: const Text('Open'),
              );
            },
          ),
          mockStore: mockStore,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refuser'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Avertissement de confidentialité'), findsNothing);
    });

    testWidgets('"Accepter et continuer" button pops with true', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showConsentDialog(context);
                },
                child: const Text('Open'),
              );
            },
          ),
          mockStore: mockStore,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accepter et continuer'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Avertissement de confidentialité'), findsNothing);
    });

    testWidgets('"Ne plus me demander" checkbox is visible and toggleable', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showConsentDialog(context),
                child: const Text('Open'),
              );
            },
          ),
          mockStore: mockStore,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Ne plus me demander'), findsOneWidget);

      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);
      expect(tester.widget<Checkbox>(checkbox).value, isFalse);

      await tester.tap(checkbox);
      await tester.pump();

      expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    });

    testWidgets('tapping outside does NOT dismiss the dialog', (tester) async {
      Object? result = 'not-called';

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showConsentDialog(context);
                },
                child: const Text('Open'),
              );
            },
          ),
          mockStore: mockStore,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap on the barrier (outside the dialog).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible.
      expect(find.text('Avertissement de confidentialité'), findsOneWidget);
      expect(result, 'not-called');
    });

    testWidgets('double-tap on "Accepter et continuer" does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showConsentDialog(context),
                child: const Text('Open'),
              );
            },
          ),
          mockStore: mockStore,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final acceptButton = find.text('Accepter et continuer');

      // Double-tap quickly. The second tap may miss because the dialog is
      // dismissed after the first tap — this is expected and must not crash.
      await tester.tap(acceptButton);
      await tester.tap(acceptButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should complete without throwing; dialog is dismissed after first tap.
      expect(find.text('Avertissement de confidentialité'), findsNothing);
    });
  });
}
