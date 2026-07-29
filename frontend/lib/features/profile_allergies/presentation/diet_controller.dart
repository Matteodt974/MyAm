import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../data/diet_local_store.dart';
import '../data/profile_sync.dart';

class DietController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final profileState = ref.watch(childProfileControllerProvider).value;
    final parentId = ref.watch(guardianIdProvider);
    if (parentId == null) {
      throw StateError('Utilisateur non authentifié');
    }
    final profileId = profileState?.activeProfileId ?? parentId;
    final isParent = profileId == parentId;
    final store = ref.read(dietLocalStoreProvider);

    final remote = await fetchProfilePreferences(ref, profileId);
    if (remote != null) {
      await store.save(profileId, remote.diets);
      return remote.diets;
    }

    return store.load(profileId, isParent: isParent);
  }

  Future<void> toggle(String diet) async {
    final current = [...(state.value ?? const <String>[])];

    if (current.contains(diet)) {
      current.remove(diet);
    } else {
      current.add(diet);
    }

    await _persist(current);
  }

  Future<void> _persist(List<String> list) async {
    state = AsyncData(list);

    final profileState = ref.read(childProfileControllerProvider).value;
    final parentId = ref.read(guardianIdProvider);
    if (parentId == null) return;
    final int profileId = profileState?.activeProfileId ?? parentId;
    await ref.read(dietLocalStoreProvider).save(profileId, list);
    await pushProfilePreferences(
      ref,
      profileId: profileId,
      isParent: profileId == parentId,
      diets: list,
    );
  }
}

final dietControllerProvider =
    AsyncNotifierProvider<DietController, List<String>>(DietController.new);
