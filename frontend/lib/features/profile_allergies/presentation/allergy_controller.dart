import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../data/allergy_local_store.dart';
import '../data/profile_sync.dart';

class AllergyController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final profileState = ref.watch(childProfileControllerProvider).value;
    final parentId = ref.watch(guardianIdProvider);
    if (parentId == null) {
      throw StateError('Utilisateur non authentifié');
    }
    final profileId = profileState?.activeProfileId ?? parentId;
    final isParent = profileId == parentId;
    final store = ref.read(allergyLocalStoreProvider);

    // Le serveur fait foi quand il repond : c'est ce qui rend le profil
    // identique d'un appareil a l'autre. Sinon on retombe sur le cache local.
    final remote = await fetchProfilePreferences(ref, profileId);
    if (remote != null) {
      await store.save(profileId, remote.allergies);
      return remote.allergies;
    }

    return store.load(profileId, isParent: isParent);
  }

  Future<void> add(String allergy) async {
    final value = allergy.trim().toLowerCase();

    if (value.isEmpty) return;

    final current = [...(state.value ?? const <String>[])];

    if (current.contains(value)) return;

    current.add(value);

    await _persist(current);
  }

  Future<void> remove(String allergy) async {
    final current = [...(state.value ?? const <String>[])]..remove(allergy);

    await _persist(current);
  }

  Future<void> _persist(List<String> list) async {
    state = AsyncData(list);

    final profileState = ref.read(childProfileControllerProvider).value;
    final parentId = ref.read(guardianIdProvider);
    if (parentId == null) return;
    final int profileId = profileState?.activeProfileId ?? parentId;
    await ref.read(allergyLocalStoreProvider).save(profileId, list);
    await pushProfilePreferences(
      ref,
      profileId: profileId,
      isParent: profileId == parentId,
      allergies: list,
    );
  }
}

final allergyControllerProvider =
    AsyncNotifierProvider<AllergyController, List<String>>(
      AllergyController.new,
    );
