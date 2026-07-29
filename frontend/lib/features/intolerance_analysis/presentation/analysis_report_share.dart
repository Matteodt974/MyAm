import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../digestive_journal/presentation/bristol_scale.dart';
import '../data/intolerance_report.dart';

/// Met en forme le rapport d'analyse pour le partage (UC-24).
///
/// Le rappel medical fait partie du texte partage : le rapport peut etre relu
/// hors de l'application, notamment par un medecin ou un(e) dietetiste.
String buildIntoleranceReportText(
  IntoleranceReport report, {
  required DateTime generatedAt,
}) {
  final dateFormat = DateFormat.yMd('fr_CA').add_Hm();
  final buffer = StringBuffer()
    ..writeln('Analyse des tendances digestives - MyAm')
    ..writeln('Généré le ${dateFormat.format(generatedAt)}')
    ..writeln();

  if (report.status != IntoleranceStatus.ok) {
    buffer
      ..writeln(report.message ?? 'Analyse non disponible.')
      ..writeln()
      ..writeln(report.medicalDisclaimer);
    return buffer.toString();
  }

  final summary = report.bristolSummary;
  if (summary != null) {
    buffer
      ..writeln(
        'Profil digestif : ${dominantProfileLabel(summary.dominantProfile)}',
      )
      ..writeln('Épisodes analysés : ${summary.entryCount}')
      ..writeln(
        '  • Constipation (types 1-2) : ${summary.constipationEpisodes}',
      )
      ..writeln('  • Normal (types 3-5) : ${summary.normalEpisodes}')
      ..writeln('  • Diarrhée (types 6-7) : ${summary.diarrheaEpisodes}')
      ..writeln();
  }

  buffer.writeln('Carences probables :');
  if (report.probableDeficiencies.isEmpty) {
    buffer.writeln('  • Aucune carence signalée');
  } else {
    for (final deficiency in report.probableDeficiencies) {
      buffer.writeln('  • $deficiency');
    }
  }
  buffer.writeln();

  buffer.writeln('Irritants alimentaires possibles :');
  if (report.possibleIrritants.isEmpty) {
    buffer.writeln('  • Aucun irritant identifié');
  } else {
    for (final irritant in report.possibleIrritants) {
      final allergens = irritant.allergens.isEmpty
          ? ''
          : ' - allergènes : ${irritant.allergens.join(', ')}';
      buffer.writeln(
        '  • ${irritant.foodName} '
        '(${irritant.episodesPreceded} épisode(s) précédé(s))$allergens',
      );
    }
  }

  buffer
    ..writeln()
    ..writeln(report.medicalDisclaimer);

  return buffer.toString();
}

/// Ouvre la feuille de partage systeme avec le rapport en texte.
Future<void> shareIntoleranceReport(
  IntoleranceReport report, {
  DateTime? generatedAt,
}) {
  final text = buildIntoleranceReportText(
    report,
    generatedAt: generatedAt ?? DateTime.now(),
  );

  return Share.share(text, subject: 'Analyse des tendances digestives - MyAm');
}
