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
}
