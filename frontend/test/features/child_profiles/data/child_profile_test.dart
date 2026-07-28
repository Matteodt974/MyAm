import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/child_profiles/data/child_profile.dart';

void main() {
  test('fromJson maps a managed child profile', () {
    final profile = ChildProfile.fromJson({
      'id': 12,
      'displayName': 'Léa',
      'allergies': ['arachide', 'lait'],
      'diets': ['VEGETARIAN'],
    });

    expect(profile.id, 12);
    expect(profile.displayName, 'Léa');
    expect(profile.isChild, isTrue);
    expect(profile.allergies, {'arachide', 'lait'});
    expect(profile.diets, {'VEGETARIAN'});
  });

  test('share payload round-trips allergies and diets', () {
    final snapshot = ChildProfileShareSnapshot(
      displayName: 'Léa',
      allergies: ['lait', 'arachide'],
      diets: ['VEGAN', 'KOSHER'],
    );

    final payload = snapshot.toPayload();
    final parsed = ChildProfile.tryParseSharePayload(payload);

    expect(parsed, isNotNull);
    expect(parsed!.displayName, 'Léa');
    expect(parsed.allergies, ['arachide', 'lait']);
    expect(parsed.diets, ['KOSHER', 'VEGAN']);
  });

  test('share payload uses the expected prefix and canonical JSON order', () {
    final payload = ChildProfileShareSnapshot(
      displayName: 'Noah',
      allergies: ['z', 'a'],
      diets: ['b', 'a'],
    ).toPayload();

    expect(payload, startsWith('MYAM_PROFILE_V1:'));

    final encoded = payload.substring('MYAM_PROFILE_V1:'.length);
    final decoded = jsonDecode(utf8.decode(base64Url.decode(encoded)));

    expect(decoded['displayName'], 'Noah');
    expect(decoded['allergies'], ['a', 'z']);
    expect(decoded['diets'], ['a', 'b']);
  });

  test('malformed share payload is ignored', () {
    expect(ChildProfile.tryParseSharePayload('not-a-payload'), isNull);
    expect(
      ChildProfile.tryParseSharePayload('MYAM_PROFILE_V1:@@@'),
      isNull,
    );
  });
}
