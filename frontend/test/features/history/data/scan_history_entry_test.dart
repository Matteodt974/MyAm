import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/history/data/scan_history_entry.dart';
import 'package:myam/features/scan_label/data/label_result.dart';

void main() {
  group('ScanHistoryEntry.fromLabelResult', () {
    test('recopie le niveau de risque retourne par le backend', () {
      const result = LabelResult(
        originalLanguage: 'en',
        riskLevel: 'DANGER',
        matchedAllergens: ['en:milk'],
      );

      final entry = ScanHistoryEntry.fromLabelResult(result);

      expect(entry.riskLevel, 'DANGER');
      expect(entry.matchedAllergens, ['en:milk']);
      expect(entry.type, ScanType.label);
    });

    test('conserve WARNING pour les ingredients indetermines', () {
      const result = LabelResult(originalLanguage: 'fr', riskLevel: 'WARNING');

      final entry = ScanHistoryEntry.fromLabelResult(result);

      expect(entry.riskLevel, 'WARNING');
    });

    test('tolere un niveau de risque absent', () {
      const result = LabelResult(originalLanguage: 'fr');

      final entry = ScanHistoryEntry.fromLabelResult(result);

      expect(entry.riskLevel, isNull);
    });
  });
}
