import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/core/errors/api_exception.dart';
import 'package:myam/features/history/data/scan_history_entry.dart';
import 'package:myam/features/history/data/scan_history_repository.dart';
import 'package:myam/features/intolerance_analysis/data/intolerance_analysis_repository.dart';
import 'package:myam/features/intolerance_analysis/data/intolerance_report.dart';
import 'package:myam/features/intolerance_analysis/presentation/analysis_controller.dart';

class MockScanHistoryRepository extends Mock implements ScanHistoryRepository {}

class MockIntoleranceAnalysisRepository extends Mock
    implements IntoleranceAnalysisRepository {}

void main() {
  late MockScanHistoryRepository mockHistory;
  late MockIntoleranceAnalysisRepository mockAnalysis;

  setUpAll(() {
    registerFallbackValue(const HistoryFilter());
    registerFallbackValue(<FoodItemPayload>[]);
  });

  setUp(() {
    mockHistory = MockScanHistoryRepository();
    mockAnalysis = MockIntoleranceAnalysisRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        scanHistoryRepositoryProvider.overrideWithValue(mockHistory),
        intoleranceAnalysisRepositoryProvider.overrideWithValue(mockAnalysis),
      ],
    );
  }

  ScanHistoryEntry historyEntry({
    required String title,
    required DateTime scannedAt,
    ScanType type = ScanType.barcode,
    List<String> allergens = const <String>[],
  }) {
    return ScanHistoryEntry(
      type: type,
      title: title,
      scannedAt: scannedAt,
      matchedAllergens: allergens,
      rawJson: '{}',
    );
  }

  const okReport = IntoleranceReport(
    status: IntoleranceStatus.ok,
    probableDeficiencies: ['Apport insuffisant probable en fibres'],
    medicalDisclaimer: 'Ces suggestions ne remplacent pas un avis médical.',
  );

  group('AnalysisController', () {
    test(
      'l’état initial est nul tant que l’analyse n’est pas lancée',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        expect(await container.read(analysisControllerProvider.future), isNull);
        verifyNever(() => mockHistory.load(filter: any(named: 'filter')));
      },
    );

    test('runAnalysis envoie le journal alimentaire des 72 h', () async {
      final scannedAt = DateTime.now().subtract(const Duration(hours: 2));
      when(() => mockHistory.load(filter: any(named: 'filter'))).thenAnswer(
        (_) async => [
          historyEntry(
            title: 'Lait 2%',
            scannedAt: scannedAt,
            allergens: const ['lait'],
          ),
        ],
      );
      when(() => mockAnalysis.analyze(any())).thenAnswer((_) async => okReport);

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(analysisControllerProvider.future);

      await container.read(analysisControllerProvider.notifier).runAnalysis();

      expect(container.read(analysisControllerProvider).value, okReport);

      final sentItems =
          verify(() => mockAnalysis.analyze(captureAny())).captured.single
              as List<FoodItemPayload>;
      expect(sentItems, hasLength(1));
      expect(sentItems.single.name, 'Lait 2%');
      expect(sentItems.single.allergens, ['lait']);
      expect(sentItems.single.scanType, 'barcode');
      expect(sentItems.single.consumedAt, scannedAt);

      // La fenetre demandee a l'historique couvre bien 72 h.
      final filter =
          verify(
                () => mockHistory.load(filter: captureAny(named: 'filter')),
              ).captured.single
              as HistoryFilter;
      final expectedFrom = DateTime.now().subtract(foodJournalWindow);
      expect(filter.from, isNotNull);
      expect(
        filter.from!.difference(expectedFrom).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('propage un statut alternatif du backend', () async {
      const insufficient = IntoleranceReport(
        status: IntoleranceStatus.insufficientFoodData,
        message:
            'Données alimentaires insuffisantes sur les 72 dernières '
            'heures.',
        medicalDisclaimer: 'Ces suggestions ne remplacent pas un avis médical.',
      );
      when(
        () => mockHistory.load(filter: any(named: 'filter')),
      ).thenAnswer((_) async => []);
      when(
        () => mockAnalysis.analyze(any()),
      ).thenAnswer((_) async => insufficient);

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(analysisControllerProvider.future);

      await container.read(analysisControllerProvider.notifier).runAnalysis();

      final report = container.read(analysisControllerProvider).value;
      expect(report?.status, IntoleranceStatus.insufficientFoodData);
      expect(report?.message, contains('insuffisantes'));
    });

    test('une erreur API place le contrôleur en AsyncError', () async {
      when(
        () => mockHistory.load(filter: any(named: 'filter')),
      ).thenAnswer((_) async => []);
      when(
        () => mockAnalysis.analyze(any()),
      ).thenThrow(const ApiException('Service indisponible.'));

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(analysisControllerProvider.future);

      await container.read(analysisControllerProvider.notifier).runAnalysis();

      expect(container.read(analysisControllerProvider).hasError, isTrue);
    });

    test('reset efface le rapport affiché', () async {
      when(
        () => mockHistory.load(filter: any(named: 'filter')),
      ).thenAnswer((_) async => []);
      when(() => mockAnalysis.analyze(any())).thenAnswer((_) async => okReport);

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(analysisControllerProvider.future);
      await container.read(analysisControllerProvider.notifier).runAnalysis();

      container.read(analysisControllerProvider.notifier).reset();

      expect(container.read(analysisControllerProvider).value, isNull);
    });
  });
}
