import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myam/features/intolerance_analysis/data/intolerance_report.dart';
import 'package:myam/features/intolerance_analysis/presentation/analysis_report_share.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_CA');
  });

  final generatedAt = DateTime(2026, 7, 27, 14, 30);

  test('le rapport partagé contient le rappel médical et les résultats', () {
    const report = IntoleranceReport(
      status: IntoleranceStatus.ok,
      bristolSummary: BristolSummary(
        entryCount: 3,
        typeCounts: {6: 2, 3: 1},
        dominantProfile: 'DIARRHEE',
        diarrheaEpisodes: 2,
        normalEpisodes: 1,
      ),
      probableDeficiencies: [
        'Irritant alimentaire possible identifié parmi vos scans récents',
      ],
      possibleIrritants: [
        IrritantSuggestion(
          foodName: 'Lait 2%',
          allergens: ['lait'],
          episodesPreceded: 2,
        ),
      ],
      medicalDisclaimer: 'Ces suggestions ne remplacent pas un avis médical.',
    );

    final text = buildIntoleranceReportText(report, generatedAt: generatedAt);

    expect(text, contains('Tendance à la diarrhée'));
    expect(text, contains('Épisodes analysés : 3'));
    expect(text, contains('Diarrhée (types 6-7) : 2'));
    expect(text, contains('Lait 2%'));
    expect(text, contains('allergènes : lait'));
    expect(text, contains('Ces suggestions ne remplacent pas un avis médical'));
  });

  test('sans carence ni irritant, le rapport le dit explicitement', () {
    const report = IntoleranceReport(
      status: IntoleranceStatus.ok,
      bristolSummary: BristolSummary(
        entryCount: 2,
        dominantProfile: 'NORMAL',
        normalEpisodes: 2,
      ),
      medicalDisclaimer: 'Ces suggestions ne remplacent pas un avis médical.',
    );

    final text = buildIntoleranceReportText(report, generatedAt: generatedAt);

    expect(text, contains('Aucune carence signalée'));
    expect(text, contains('Aucun irritant identifié'));
  });

  test('un statut alternatif partage le message explicatif du backend', () {
    const report = IntoleranceReport(
      status: IntoleranceStatus.noJournalEntries,
      message: 'Aucune entrée dans votre journal digestif.',
      medicalDisclaimer: 'Ces suggestions ne remplacent pas un avis médical.',
    );

    final text = buildIntoleranceReportText(report, generatedAt: generatedAt);

    expect(text, contains('Aucune entrée dans votre journal digestif.'));
    expect(text, contains('Ces suggestions ne remplacent pas un avis médical'));
    expect(text, isNot(contains('Carences probables')));
  });
}
