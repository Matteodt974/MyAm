import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../data/allergy_local_store.dart';

class AllergyController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() {
    final profileState = ref.watch(childProfileControllerProvider).value;
    final parentId = ref.watch(guardianIdProvider);
    if (parentId == null) {
      throw StateError('Utilisateur non authentifié');
    }
    final profileId = profileState?.activeProfileId ?? parentId;
    return ref
        .read(allergyLocalStoreProvider)
        .load(profileId, isParent: profileId == parentId);
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
  }
}

final allergyControllerProvider =
    AsyncNotifierProvider<AllergyController, List<String>>(
      AllergyController.new,
    );
