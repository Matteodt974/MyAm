import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/profile_allergies/data/allergy_severity.dart';

void main() {
  group('AllergySeverity', () {
    test('UC-13 3b : un sous-profil enfant est sévère par défaut', () {
      expect(
        AllergySeverity.defaultFor(isChildProfile: true),
        AllergySeverity.severe,
      );
      expect(
        AllergySeverity.defaultFor(isChildProfile: false),
        AllergySeverity.moderate,
      );
    });

    test('expose les trois niveaux du cahier des charges', () {
      expect(AllergySeverity.values.map((s) => s.label), [
        'Légère',
        'Modérée',
        'Sévère',
      ]);
    });

    test('le niveau sévère mentionne le risque anaphylactique', () {
      expect(AllergySeverity.severe.hint, 'risque anaphylactique');
      expect(AllergySeverity.light.hint, isNull);
      expect(AllergySeverity.moderate.hint, isNull);
    });

    test('relit les valeurs stockées et retombe sur modérée si inconnue', () {
      expect(AllergySeverity.fromStorage('severe'), AllergySeverity.severe);
      expect(AllergySeverity.fromStorage('light'), AllergySeverity.light);
      expect(AllergySeverity.fromStorage('inconnu'), AllergySeverity.moderate);
      expect(AllergySeverity.fromStorage(null), AllergySeverity.moderate);
    });
  });
}
