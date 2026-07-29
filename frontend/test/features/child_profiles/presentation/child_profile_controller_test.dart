import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myam/features/child_profiles/data/active_profile_store.dart';
import 'package:myam/features/child_profiles/data/child_profile.dart';
import 'package:myam/features/child_profiles/data/child_profile_repository.dart';
import 'package:myam/features/child_profiles/presentation/child_profile_controller.dart';
import 'package:myam/features/profile_allergies/data/allergy_local_store.dart';
import 'package:myam/features/profile_allergies/data/diet_local_store.dart';
import 'package:myam/features/profile_allergies/data/profile_preferences_repository.dart';
import 'package:myam/features/profile_allergies/presentation/allergy_controller.dart';

class MockChildProfileRepository extends Mock
    implements ChildProfileRepository {}

class MockActiveProfileStore extends Mock implements ActiveProfileStore {}

class MockAllergyLocalStore extends Mock implements AllergyLocalStore {}

class MockDietLocalStore extends Mock implements DietLocalStore {}

/// Un profil absent de [_preferences] simule un serveur injoignable : le
/// controleur doit alors retomber sur le stockage local.
class _StubPreferencesRepository implements ProfilePreferencesRepository {
  _StubPreferencesRepository(Map<int, ProfilePreferences> preferences)
    : _preferences = Map.of(preferences);

  final Map<int, ProfilePreferences> _preferences;

  @override
  Future<ProfilePreferences> fetch(int profileId) async {
    final preferences = _preferences[profileId];
    if (preferences == null) throw Exception('hors ligne');
    return preferences;
  }

  @override
  Future<ProfilePreferences> replace(
    int profileId, {
    required List<String> allergies,
    required List<String> diets,
  }) async {
    final updated = ProfilePreferences(allergies: allergies, diets: diets);
    _preferences[profileId] = updated;
    return updated;
  }
}

void main() {
  const guardianId = 7;
  const lea = ChildProfile(id: 12, displayName: 'Léa', isChild: true);
  const noah = ChildProfile(id: 13, displayName: 'Noah', isChild: true);

  late MockChildProfileRepository repository;
  late MockActiveProfileStore activeProfileStore;
  late MockDietLocalStore dietLocalStore;

  ProviderContainer createContainer({
    MockAllergyLocalStore? allergyLocalStore,
    Map<int, ProfilePreferences> remotePreferences = const {},
  }) {
    return ProviderContainer(
      overrides: [
        guardianIdProvider.overrideWithValue(guardianId),
        childProfileRepositoryProvider.overrideWithValue(repository),
        activeProfileStoreProvider.overrideWithValue(activeProfileStore),
        if (allergyLocalStore != null)
          allergyLocalStoreProvider.overrideWithValue(allergyLocalStore),
        // La synchronisation lit toujours les deux listes du profil.
        dietLocalStoreProvider.overrideWithValue(dietLocalStore),
        // Sans cette surcharge, l'hydratation du profil taperait le vrai reseau.
        profilePreferencesRepositoryProvider.overrideWithValue(
          _StubPreferencesRepository(remotePreferences),
        ),
      ],
    );
  }

  setUp(() {
    repository = MockChildProfileRepository();
    activeProfileStore = MockActiveProfileStore();
    dietLocalStore = MockDietLocalStore();

    when(
      () => dietLocalStore.load(any(), isParent: any(named: 'isParent')),
    ).thenAnswer((_) async => <String>[]);
    when(() => dietLocalStore.save(any(), any())).thenAnswer((_) async {});

    when(() => repository.list(guardianId)).thenAnswer((_) async => [lea]);
    when(() => activeProfileStore.load()).thenAnswer((_) async => null);
    when(() => activeProfileStore.save(any())).thenAnswer((_) async {});
  });

  test(
    'build includes the parent and falls back to the parent profile',
    () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = await container.read(childProfileControllerProvider.future);

      expect(state.profiles, hasLength(2));
      expect(state.profiles.first.id, guardianId);
      expect(state.profiles.first.displayName, 'Moi');
      expect(state.profiles.first.isChild, isFalse);
      expect(state.profiles.last, same(lea));
      expect(state.activeProfileId, guardianId);
    },
  );

  test('build restores a stored child profile when it still exists', () async {
    when(() => activeProfileStore.load()).thenAnswer((_) async => lea.id);
    final container = createContainer();
    addTearDown(container.dispose);

    final state = await container.read(childProfileControllerProvider.future);

    expect(state.activeProfileId, lea.id);
    expect(state.activeProfile, lea);
  });

  test(
    'create, rename and delete update the profiles and active selection',
    () async {
      when(
        () => repository.create(guardianId, 'Noah'),
      ).thenAnswer((_) async => noah);
      when(() => repository.update(guardianId, lea.id, 'Léa-Rose')).thenAnswer(
        (_) async =>
            const ChildProfile(id: 12, displayName: 'Léa-Rose', isChild: true),
      );
      when(
        () => repository.delete(guardianId, noah.id),
      ).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);
      await container.read(childProfileControllerProvider.future);
      final controller = container.read(
        childProfileControllerProvider.notifier,
      );

      await controller.createChild('  Noah  ');
      expect(
        container.read(childProfileControllerProvider).value?.activeProfileId,
        noah.id,
      );
      verify(() => repository.create(guardianId, 'Noah')).called(1);
      verify(() => activeProfileStore.save(noah.id)).called(1);

      await controller.renameChild(lea.id, '  Léa-Rose  ');
      final renamedProfiles =
          container.read(childProfileControllerProvider).value?.profiles ?? [];
      expect(
        renamedProfiles
            .singleWhere((profile) => profile.id == lea.id)
            .displayName,
        'Léa-Rose',
      );
      verify(() => repository.update(guardianId, lea.id, 'Léa-Rose')).called(1);

      await controller.deleteChild(noah.id);
      final state = container.read(childProfileControllerProvider).value;
      expect(state?.profiles.any((profile) => profile.id == noah.id), isFalse);
      expect(state?.activeProfileId, guardianId);
      verify(() => repository.delete(guardianId, noah.id)).called(1);
      verify(() => activeProfileStore.save(guardianId)).called(1);
    },
  );

  test('select persists valid profiles and ignores unknown profiles', () async {
    final container = createContainer();
    addTearDown(container.dispose);
    await container.read(childProfileControllerProvider.future);
    final controller = container.read(childProfileControllerProvider.notifier);

    await controller.select(lea.id);
    await controller.select(999);

    expect(
      container.read(childProfileControllerProvider).value?.activeProfileId,
      lea.id,
    );
    verify(() => activeProfileStore.save(lea.id)).called(1);
    verifyNever(() => activeProfileStore.save(999));
  });

  test('changing the active profile reloads that profile allergies', () async {
    when(() => activeProfileStore.load()).thenAnswer((_) async => lea.id);
    final allergyLocalStore = MockAllergyLocalStore();
    when(
      () => allergyLocalStore.load(lea.id, isParent: false),
    ).thenAnswer((_) async => ['arachide']);
    when(
      () => allergyLocalStore.load(guardianId, isParent: true),
    ).thenAnswer((_) async => ['lait']);

    final container = createContainer(allergyLocalStore: allergyLocalStore);
    addTearDown(container.dispose);

    await container.read(childProfileControllerProvider.future);
    expect(await container.read(allergyControllerProvider.future), [
      'arachide',
    ]);

    await container
        .read(childProfileControllerProvider.notifier)
        .select(guardianId);

    expect(await container.read(allergyControllerProvider.future), ['lait']);
  });

  test('server preferences win over the local cache and refresh it', () async {
    final allergyLocalStore = MockAllergyLocalStore();
    when(
      () => allergyLocalStore.load(guardianId, isParent: true),
    ).thenAnswer((_) async => ['valeur périmée']);
    when(() => allergyLocalStore.save(any(), any())).thenAnswer((_) async {});

    final container = createContainer(
      allergyLocalStore: allergyLocalStore,
      remotePreferences: const {
        guardianId: ProfilePreferences(allergies: ['lait'], diets: ['VEGAN']),
      },
    );
    addTearDown(container.dispose);

    await container.read(childProfileControllerProvider.future);

    expect(await container.read(allergyControllerProvider.future), ['lait']);
    verify(() => allergyLocalStore.save(guardianId, ['lait'])).called(1);
  });

  test('an edit survives a profile round trip', () async {
    final allergyLocalStore = MockAllergyLocalStore();
    when(
      () => allergyLocalStore.load(guardianId, isParent: true),
    ).thenAnswer((_) async => ['lait']);
    when(
      () => allergyLocalStore.load(lea.id, isParent: false),
    ).thenAnswer((_) async => ['arachide']);
    when(() => allergyLocalStore.save(any(), any())).thenAnswer((_) async {});

    final container = createContainer(
      allergyLocalStore: allergyLocalStore,
      remotePreferences: const {
        guardianId: ProfilePreferences(allergies: ['lait'], diets: []),
      },
    );
    addTearDown(container.dispose);

    await container.read(childProfileControllerProvider.future);
    await container.read(allergyControllerProvider.future);

    await container.read(allergyControllerProvider.notifier).add('œuf');

    final profiles = container.read(childProfileControllerProvider.notifier);
    await profiles.select(lea.id);
    await container.read(allergyControllerProvider.future);
    await profiles.select(guardianId);

    // Le serveur a bien recu l'ajout : la reconstruction ne doit pas le perdre.
    expect(await container.read(allergyControllerProvider.future), [
      'lait',
      'œuf',
    ]);
  });
}
