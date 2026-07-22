import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/diet_local_store.dart';

class DietController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() {
    return ref.read(dietLocalStoreProvider).load();
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

    await ref.read(dietLocalStoreProvider).save(list);
  }
}

final dietControllerProvider =
    AsyncNotifierProvider<DietController, List<String>>(DietController.new);
