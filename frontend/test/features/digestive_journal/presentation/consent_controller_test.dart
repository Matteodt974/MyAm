import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/digestive_journal/data/consent_local_store.dart';
import 'package:myam/features/digestive_journal/presentation/consent_controller.dart';

class MockConsentLocalStore extends Mock implements ConsentLocalStore {}

void main() {
  late MockConsentLocalStore mockStore;

  setUp(() {
    mockStore = MockConsentLocalStore();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [consentLocalStoreProvider.overrideWithValue(mockStore)],
    );
  }

  group('ConsentController', () {
    test('build returns granted when store has true', () async {
      when(() => mockStore.load()).thenAnswer((_) async => true);

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(consentControllerProvider.future);

      expect(state, ConsentDecision.granted);
      verify(() => mockStore.load()).called(1);
    });

    test('build returns undecided when store has false', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(consentControllerProvider.future);

      expect(state, ConsentDecision.undecided);
      verify(() => mockStore.load()).called(1);
    });

    test('build returns undecided when store is empty', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(consentControllerProvider.future);

      expect(state, ConsentDecision.undecided);
      verify(() => mockStore.load()).called(1);
    });

    test('giveConsent(rememberChoice: true) calls store.save(true) and state '
        'becomes granted', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);
      when(() => mockStore.save(true)).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.future);
      final controller = container.read(consentControllerProvider.notifier);

      await controller.giveConsent(rememberChoice: true);

      final state = container.read(consentControllerProvider);
      expect(state.value, ConsentDecision.granted);
      verify(() => mockStore.save(true)).called(1);
    });

    test('giveConsent(rememberChoice: false) does NOT call store.save() and '
        'state becomes granted', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.future);
      final controller = container.read(consentControllerProvider.notifier);

      await controller.giveConsent(rememberChoice: false);

      final state = container.read(consentControllerProvider);
      expect(state.value, ConsentDecision.granted);
      verifyNever(() => mockStore.save(any()));
    });

    test('refuseConsent sets state to refused', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.future);
      final controller = container.read(consentControllerProvider.notifier);

      controller.refuseConsent();

      final state = container.read(consentControllerProvider);
      expect(state.value, ConsentDecision.refused);
    });

    test(
      'resetConsent calls store.clear() and state becomes undecided',
      () async {
        when(() => mockStore.load()).thenAnswer((_) async => true);
        when(() => mockStore.clear()).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        await container.read(consentControllerProvider.future);
        final controller = container.read(consentControllerProvider.notifier);

        await controller.resetConsent();

        final state = container.read(consentControllerProvider);
        expect(state.value, ConsentDecision.undecided);
        verify(() => mockStore.clear()).called(1);
      },
    );

    test('resetConsent from undecided state is idempotent', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);
      when(() => mockStore.clear()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.future);
      final controller = container.read(consentControllerProvider.notifier);

      await expectLater(controller.resetConsent(), completes);

      final state = container.read(consentControllerProvider);
      expect(state.value, ConsentDecision.undecided);
      verify(() => mockStore.clear()).called(1);
    });

    test('giveConsent handles storage write failure gracefully and state still '
        'becomes granted', () async {
      when(() => mockStore.load()).thenAnswer((_) async => false);
      when(() => mockStore.save(true)).thenThrow(Exception('Storage error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(consentControllerProvider.future);
      final controller = container.read(consentControllerProvider.notifier);

      await controller.giveConsent(rememberChoice: true);

      final state = container.read(consentControllerProvider);
      expect(state.value, ConsentDecision.granted);
      verify(() => mockStore.save(true)).called(1);
    });
  });
}
