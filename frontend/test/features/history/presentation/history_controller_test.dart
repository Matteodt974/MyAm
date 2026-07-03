import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/history/data/scan_history_entry.dart';
import 'package:myam/features/history/data/scan_history_repository.dart';
import 'package:myam/features/history/presentation/history_controller.dart';

class MockScanHistoryRepository extends Mock implements ScanHistoryRepository {}

void main() {
  late MockScanHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockScanHistoryRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        scanHistoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

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

  group('HistoryController', () {
    test('build loads entries from the repository', () async {
      final entries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'A'),
        makeEntry(id: 2, type: ScanType.dish, title: 'B'),
      ];
      when(() => mockRepository.load(filter: null)).thenAnswer(
        (_) async => entries,
      );

      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(historyControllerProvider.future);

      expect(state, entries);
      verify(() => mockRepository.load(filter: null)).called(1);
    });

    test('applyFilter sets the filter and reloads entries', () async {
      final allEntries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'Barcode'),
        makeEntry(id: 2, type: ScanType.dish, title: 'Dish'),
      ];
      final filter = const HistoryFilter(types: [ScanType.barcode]);
      final filteredEntries = [allEntries.first];

      when(() => mockRepository.load(filter: null)).thenAnswer(
        (_) async => allEntries,
      );
      when(() => mockRepository.load(filter: filter)).thenAnswer(
        (_) async => filteredEntries,
      );

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.applyFilter(filter);

      final state = container.read(historyControllerProvider);
      expect(state.value, filteredEntries);
      verify(() => mockRepository.load(filter: filter)).called(1);
    });

    test('delete removes the entry and refreshes the list', () async {
      final entries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'To delete'),
        makeEntry(id: 2, type: ScanType.dish, title: 'Remaining'),
      ];
      var loadCount = 0;
      when(() => mockRepository.load(filter: null)).thenAnswer((_) async {
        loadCount++;
        return loadCount == 1 ? entries : [entries.last];
      });
      when(() => mockRepository.delete(1)).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.delete(1);

      final state = container.read(historyControllerProvider);
      expect(state.value, [entries.last]);
      verify(() => mockRepository.delete(1)).called(1);
      verify(() => mockRepository.load(filter: null)).called(2);
    });

    test('clearFilter removes the filter and reloads the full history',
        () async {
      final allEntries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'Barcode'),
        makeEntry(id: 2, type: ScanType.dish, title: 'Dish'),
      ];
      final filter = const HistoryFilter(types: [ScanType.barcode]);
      final filteredEntries = [allEntries.first];

      when(() => mockRepository.load(filter: null)).thenAnswer(
        (_) async => allEntries,
      );
      when(() => mockRepository.load(filter: filter)).thenAnswer(
        (_) async => filteredEntries,
      );

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.applyFilter(filter);
      expect(container.read(historyControllerProvider).value, filteredEntries);

      await controller.clearFilter();

      final state = container.read(historyControllerProvider);
      expect(state.value, allEntries);
      verify(() => mockRepository.load(filter: null)).called(2);
      verify(() => mockRepository.load(filter: filter)).called(1);
    });

    test('clearAll deletes every entry and refreshes the list', () async {
      final entries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'A'),
        makeEntry(id: 2, type: ScanType.dish, title: 'B'),
      ];
      when(() => mockRepository.load(filter: null)).thenAnswer(
        (_) async => entries,
      );
      when(() => mockRepository.clear()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.clearAll();

      final state = container.read(historyControllerProvider);
      expect(state.value, entries);
      verify(() => mockRepository.clear()).called(1);
      verify(() => mockRepository.load(filter: null)).called(2);
    });

    test('exportCsv returns early while the controller is still loading',
        () async {
      when(() => mockRepository.load(filter: null)).thenAnswer((_) async {
        // Keep the controller in a loading state long enough to exercise
        // the early-return guard.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return <ScanHistoryEntry>[];
      });

      final container = createContainer();
      addTearDown(container.dispose);

      // Trigger an async build without awaiting it.
      container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await expectLater(controller.exportCsv(), completes);

      // Allow the delayed load to finish before the container is disposed.
      await container.read(historyControllerProvider.future);
    });
  });
}
