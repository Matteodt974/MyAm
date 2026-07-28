import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../data/diet_local_store.dart';

class DietController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() {
    final profileState = ref.watch(childProfileControllerProvider).value;
    final parentId = ref.watch(guardianIdProvider);
    if (parentId == null) {
      throw StateError('Utilisateur non authentifié');
    }
    final profileId = profileState?.activeProfileId ?? parentId;
    return ref
        .read(dietLocalStoreProvider)
        .load(profileId, isParent: profileId == parentId);
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
  }
}

final dietControllerProvider =
    AsyncNotifierProvider<DietController, List<String>>(DietController.new);
