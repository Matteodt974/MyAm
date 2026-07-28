import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/child_profiles/data/child_profile.dart';

/// Le payload est produit par l'emetteur du QR, pas par l'application : on le
/// fabrique ici a la main pour figer le format attendu par le lecteur.
String sharePayload(Map<String, dynamic> json) {
  return 'MYAM_PROFILE_V1:${base64Url.encode(utf8.encode(jsonEncode(json)))}';
}

void main() {
  test('fromJson maps a managed child profile', () {
    final profile = ChildProfile.fromJson({'id': 12, 'displayName': 'Léa'});

    expect(profile.id, 12);
    expect(profile.displayName, 'Léa');
    expect(profile.isChild, isTrue);
  });

  test('share payload carries allergies and diets', () {
    final parsed = ChildProfile.tryParseSharePayload(
      sharePayload({
        'displayName': 'Léa',
        'allergies': ['arachide', 'lait'],
        'diets': ['KOSHER', 'VEGAN'],
      }),
    );

    expect(parsed, isNotNull);
    expect(parsed!.displayName, 'Léa');
    expect(parsed.allergies, ['arachide', 'lait']);
    expect(parsed.diets, ['KOSHER', 'VEGAN']);
  });

  test('share payload without a name falls back to a default', () {
    final parsed = ChildProfile.tryParseSharePayload(
      sharePayload({
        'allergies': ['lait'],
      }),
    );

    expect(parsed, isNotNull);
    expect(parsed!.displayName, 'Profil enfant');
    expect(parsed.diets, isEmpty);
  });

  test('malformed share payload is ignored', () {
    expect(ChildProfile.tryParseSharePayload('not-a-payload'), isNull);
    expect(ChildProfile.tryParseSharePayload('MYAM_PROFILE_V1:@@@'), isNull);
  });
}
