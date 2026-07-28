import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/child_profiles/data/active_profile_store.dart';
import 'package:myam/features/child_profiles/data/child_profile_repository.dart';
import 'package:myam/features/child_profiles/presentation/child_profile_controller.dart';
import 'package:myam/features/history/data/scan_history_entry.dart';
import 'package:myam/features/history/data/scan_history_repository.dart';
import 'package:myam/features/history/presentation/history_controller.dart';

class MockScanHistoryRepository extends Mock implements ScanHistoryRepository {}

class MockChildProfileRepository extends Mock
    implements ChildProfileRepository {}

class MockActiveProfileStore extends Mock implements ActiveProfileStore {}

void main() {
  late MockScanHistoryRepository mockRepository;
  late MockChildProfileRepository mockChildProfileRepository;
  late MockActiveProfileStore mockActiveProfileStore;

  const profileId = 1;

  setUp(() {
    mockRepository = MockScanHistoryRepository();
    mockChildProfileRepository = MockChildProfileRepository();
    mockActiveProfileStore = MockActiveProfileStore();

    when(
      () => mockChildProfileRepository.list(profileId),
    ).thenAnswer((_) async => []);
    when(() => mockActiveProfileStore.load()).thenAnswer((_) async => null);
    when(() => mockActiveProfileStore.save(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        scanHistoryRepositoryProvider.overrideWithValue(mockRepository),
        guardianIdProvider.overrideWithValue(profileId),
        childProfileRepositoryProvider.overrideWithValue(
          mockChildProfileRepository,
        ),
        activeProfileStoreProvider.overrideWithValue(mockActiveProfileStore),
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
      when(
        () => mockRepository.load(profileId, filter: null),
      ).thenAnswer((_) async => entries);

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);

      final state = await container.read(historyControllerProvider.future);

      expect(state, entries);
      verify(() => mockRepository.load(profileId, filter: null)).called(1);
    });

    test('applyFilter sets the filter and reloads entries', () async {
      final allEntries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'Barcode'),
        makeEntry(id: 2, type: ScanType.dish, title: 'Dish'),
      ];
      final filter = const HistoryFilter(types: [ScanType.barcode]);
      final filteredEntries = [allEntries.first];

      when(
        () => mockRepository.load(profileId, filter: null),
      ).thenAnswer((_) async => allEntries);
      when(
        () => mockRepository.load(profileId, filter: filter),
      ).thenAnswer((_) async => filteredEntries);

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.applyFilter(filter);

      final state = container.read(historyControllerProvider);
      expect(state.value, filteredEntries);
      verify(() => mockRepository.load(profileId, filter: filter)).called(1);
    });

    test('delete removes the entry and refreshes the list', () async {
      final entries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'To delete'),
        makeEntry(id: 2, type: ScanType.dish, title: 'Remaining'),
      ];
      var loadCount = 0;
      when(() => mockRepository.load(profileId, filter: null)).thenAnswer((
        _,
      ) async {
        loadCount++;
        return loadCount == 1 ? entries : [entries.last];
      });
      when(() => mockRepository.delete(1, profileId)).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.delete(1);

      final state = container.read(historyControllerProvider);
      expect(state.value, [entries.last]);
      verify(() => mockRepository.delete(1, profileId)).called(1);
      verify(() => mockRepository.load(profileId, filter: null)).called(2);
    });

    test(
      'clearFilter removes the filter and reloads the full history',
      () async {
        final allEntries = [
          makeEntry(id: 1, type: ScanType.barcode, title: 'Barcode'),
          makeEntry(id: 2, type: ScanType.dish, title: 'Dish'),
        ];
        final filter = const HistoryFilter(types: [ScanType.barcode]);
        final filteredEntries = [allEntries.first];

        when(
          () => mockRepository.load(profileId, filter: null),
        ).thenAnswer((_) async => allEntries);
        when(
          () => mockRepository.load(profileId, filter: filter),
        ).thenAnswer((_) async => filteredEntries);

        final container = createContainer();
        addTearDown(container.dispose);
        await container.read(childProfileControllerProvider.future);

        await container.read(historyControllerProvider.future);
        final controller = container.read(historyControllerProvider.notifier);

        await controller.applyFilter(filter);
        expect(
          container.read(historyControllerProvider).value,
          filteredEntries,
        );

        await controller.clearFilter();

        final state = container.read(historyControllerProvider);
        expect(state.value, allEntries);
        verify(() => mockRepository.load(profileId, filter: null)).called(2);
        verify(() => mockRepository.load(profileId, filter: filter)).called(1);
      },
    );

    test('clearAll deletes every entry and refreshes the list', () async {
      final entries = [
        makeEntry(id: 1, type: ScanType.barcode, title: 'A'),
        makeEntry(id: 2, type: ScanType.dish, title: 'B'),
      ];
      when(
        () => mockRepository.load(profileId, filter: null),
      ).thenAnswer((_) async => entries);
      when(() => mockRepository.clear(profileId)).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);

      await container.read(historyControllerProvider.future);
      final controller = container.read(historyControllerProvider.notifier);

      await controller.clearAll();

      final state = container.read(historyControllerProvider);
      expect(state.value, entries);
      verify(() => mockRepository.clear(profileId)).called(1);
      verify(() => mockRepository.load(profileId, filter: null)).called(2);
    });

    test(
      'exportCsv returns early while the controller is still loading',
      () async {
        when(() => mockRepository.load(profileId, filter: null)).thenAnswer((
          _,
        ) async {
          // Keep the controller in a loading state long enough to exercise
          // the early-return guard.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <ScanHistoryEntry>[];
        });

        final container = createContainer();
        addTearDown(container.dispose);
        await container.read(childProfileControllerProvider.future);

        // Trigger an async build without awaiting it.
        container.read(historyControllerProvider.future);
        final controller = container.read(historyControllerProvider.notifier);

        await expectLater(controller.exportCsv(), completes);

        // Allow the delayed load to finish before the container is disposed.
        await container.read(historyControllerProvider.future);
      },
    );
  });
}
