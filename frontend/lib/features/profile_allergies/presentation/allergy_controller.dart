import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/allergy_local_store.dart';

class AllergyController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() {
    return ref.read(allergyLocalStoreProvider).load();
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

    await ref.read(allergyLocalStoreProvider).save(list);
  }
}

final allergyControllerProvider =
    AsyncNotifierProvider<AllergyController, List<String>>(
      AllergyController.new,
    );
