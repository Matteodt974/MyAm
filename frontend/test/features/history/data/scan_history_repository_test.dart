import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/history/data/scan_history_database.dart';
import 'package:myam/features/history/data/scan_history_entry.dart';
import 'package:myam/features/history/data/scan_history_repository.dart';

class MockScanHistoryDatabase extends Mock implements ScanHistoryDatabase {}

void main() {
  late MockScanHistoryDatabase mockDatabase;
  late ScanHistoryRepository repository;

  setUp(() {
    mockDatabase = MockScanHistoryDatabase();
    repository = ScanHistoryRepository(mockDatabase);
  });

  ScanHistoryEntry makeEntry({
    int? id,
    required ScanType type,
    required String title,
  }) {
    return ScanHistoryEntry(
      id: id,
      type: type,
      title: title,
      scannedAt: DateTime(2025, 1, 1),
      rawJson: '{"test": true}',
    );
  }

  group('ScanHistoryRepository.save', () {
    test('calls database.insert', () async {
      final entry = makeEntry(type: ScanType.barcode, title: 'Product');
      when(
        () => mockDatabase.insert(entry),
      ).thenAnswer((_) async => entry.copyWith(id: 1));

      await repository.save(entry);

      verify(() => mockDatabase.insert(entry)).called(1);
    });

    test('does not throw when insert throws', () async {
      final entry = makeEntry(type: ScanType.dish, title: 'Dish');
      when(() => mockDatabase.insert(entry)).thenThrow(Exception('db error'));

      await expectLater(repository.save(entry), completes);

      verify(() => mockDatabase.insert(entry)).called(1);
    });
  });

  group('ScanHistoryRepository.load', () {
    test(
      'returns entries from database.getAll when no filter is provided',
      () async {
        final entries = [
          makeEntry(id: 1, type: ScanType.barcode, title: 'A'),
          makeEntry(id: 2, type: ScanType.label, title: 'B'),
        ];
        when(() => mockDatabase.getAll()).thenAnswer((_) async => entries);

        final result = await repository.load();

        expect(result, entries);
        verify(() => mockDatabase.getAll()).called(1);
        verifyNever(() => mockDatabase.getFiltered());
      },
    );

    test(
      'delegates to database.getFiltered when a filter is provided',
      () async {
        final entries = [makeEntry(id: 3, type: ScanType.dish, title: 'C')];
        final filter = HistoryFilter(
          from: DateTime(2025, 1, 1),
          to: DateTime(2025, 1, 2),
          types: [ScanType.dish],
          riskLevels: ['SAFE'],
          allergen: 'lactose',
        );
        when(
          () => mockDatabase.getFiltered(
            from: filter.from,
            to: filter.to,
            types: filter.types,
            riskLevels: filter.riskLevels,
            allergen: filter.allergen,
          ),
        ).thenAnswer((_) async => entries);

        final result = await repository.load(filter: filter);

        expect(result, entries);
        verify(
          () => mockDatabase.getFiltered(
            from: filter.from,
            to: filter.to,
            types: filter.types,
            riskLevels: filter.riskLevels,
            allergen: filter.allergen,
          ),
        ).called(1);
        verifyNever(() => mockDatabase.getAll());
      },
    );
  });

  group('ScanHistoryRepository.delete', () {
    test('calls database.delete with the given id', () async {
      when(() => mockDatabase.delete(42)).thenAnswer((_) async {});

      await repository.delete(42);

      verify(() => mockDatabase.delete(42)).called(1);
    });

    test('clear calls database.deleteAll', () async {
      when(() => mockDatabase.deleteAll()).thenAnswer((_) async {});

      await repository.clear();

      verify(() => mockDatabase.deleteAll()).called(1);
    });
  });

  group('providers', () {
    test('scanHistoryRepositoryProvider exposes a repository instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(scanHistoryRepositoryProvider);

      expect(repository, isA<ScanHistoryRepository>());
    });
  });
}
