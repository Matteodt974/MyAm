import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trusted_item_local_store.dart';

class TrustedItemController extends AsyncNotifier<List<TrustedItem>> {
  @override
  Future<List<TrustedItem>> build() {
    return ref.read(trustedItemLocalStoreProvider).load();
  }

  Future<void> add(TrustedItem item) async {
    final current = [...(state.value ?? const <TrustedItem>[])];

    if (current.any((existing) => existing.id == item.id)) {
      return;
    }

    current.add(item);
    await _persist(current);
  }

  Future<void> remove(String id) async {
    final current = [...(state.value ?? const <TrustedItem>[])];
    current.removeWhere((item) => item.id == id);

    await _persist(current);
  }

  Future<void> _persist(List<TrustedItem> list) async {
    state = AsyncData(list);
    await ref.read(trustedItemLocalStoreProvider).save(list);
  }
}

final trustedItemControllerProvider =
    AsyncNotifierProvider<TrustedItemController, List<TrustedItem>>(
      TrustedItemController.new,
    );