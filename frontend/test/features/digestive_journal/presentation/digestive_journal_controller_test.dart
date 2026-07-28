import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/errors/api_exception.dart';
import 'package:myam/features/digestive_journal/data/digestive_entry.dart';
import 'package:myam/features/digestive_journal/data/digestive_journal_repository.dart';
import 'package:myam/features/digestive_journal/presentation/digestive_journal_controller.dart';

class MockDigestiveJournalRepository extends Mock
    implements DigestiveJournalRepository {}

void main() {
  late MockDigestiveJournalRepository mockRepository;

  setUp(() {
    mockRepository = MockDigestiveJournalRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        digestiveJournalRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

  DigestiveEntry entry({int id = 1, int bristolType = 4}) {
    return DigestiveEntry(
      id: id,
      bristolType: bristolType,
      occurredAt: DateTime.utc(2026, 7, 26, 8),
    );
  }

  group('DigestiveJournalController', () {
    test('build charge les entrées depuis le repository', () async {
      final entries = [entry(id: 1), entry(id: 2, bristolType: 6)];
      when(() => mockRepository.list()).thenAnswer((_) async => entries);

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        digestiveJournalControllerProvider.future,
      );

      expect(state, entries);
      verify(() => mockRepository.list()).called(1);
    });

    test('addEntry crée l’entrée puis recharge la liste', () async {
      when(() => mockRepository.list()).thenAnswer((_) async => [entry()]);
      when(
        () => mockRepository.create(
          bristolType: any(named: 'bristolType'),
          occurredAt: any(named: 'occurredAt'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => entry(id: 3, bristolType: 6));

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(digestiveJournalControllerProvider.future);

      await container
          .read(digestiveJournalControllerProvider.notifier)
          .addEntry(
            bristolType: 6,
            occurredAt: DateTime.utc(2026, 7, 26, 9),
            notes: 'crampes',
          );

      verify(
        () => mockRepository.create(
          bristolType: 6,
          occurredAt: DateTime.utc(2026, 7, 26, 9),
          notes: 'crampes',
        ),
      ).called(1);
      // 1 chargement initial + 1 rechargement apres creation.
      verify(() => mockRepository.list()).called(2);
    });

    test('addEntry propage l’erreur à l’appelant', () async {
      when(() => mockRepository.list()).thenAnswer((_) async => []);
      when(
        () => mockRepository.create(
          bristolType: any(named: 'bristolType'),
          occurredAt: any(named: 'occurredAt'),
          notes: any(named: 'notes'),
        ),
      ).thenThrow(const ApiException('Requête invalide.'));

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(digestiveJournalControllerProvider.future);

      await expectLater(
        container
            .read(digestiveJournalControllerProvider.notifier)
            .addEntry(bristolType: 9, occurredAt: DateTime.utc(2026)),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
