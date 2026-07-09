import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scan_barcode/data/barcode_repository.dart';
import '../data/trusted_item_local_store.dart';
import 'allergy_controller.dart';
import 'language_controller.dart';

class TrustedItemController extends AsyncNotifier<List<TrustedItem>> {
  @override
  Future<List<TrustedItem>> build() {
    ref.listen<AsyncValue<List<String>>>(allergyControllerProvider, (
      previous,
      next,
    ) {
      final nextAllergies = next.value;
      if (previous == null || previous.value == null || nextAllergies == null) {
        return;
      }
      unawaited(_revokeUnsafeBarcodeItems(nextAllergies));
    });

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

  Future<void> _revokeUnsafeBarcodeItems(List<String> allergies) async {
    final current = state.value;
    if (current == null || current.isEmpty) return;

    final repository = ref.read(barcodeRepositoryProvider);
    final language = await ref.read(languageControllerProvider.future);
    final survivors = <TrustedItem>[];

    for (final item in current) {
      if (item.id.startsWith('dish:')) {
        survivors.add(item);
        continue;
      }

      try {
        final product = await repository.lookup(
          item.ean,
          allergies,
          language,
          const [],
        );
        if (product.riskLevel == 'SAFE') {
          survivors.add(item);
        }
      } catch (_) {
        survivors.add(item);
      }
    }

    if (survivors.length != current.length) {
      await _persist(survivors);
    }
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
