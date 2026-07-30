import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/parent_scan_alert_controller.dart';
import '../../history/data/scan_history_entry.dart';
import '../../history/presentation/history_persistence.dart';
import '../../profile_allergies/presentation/allergy_controller.dart';
import '../../profile_allergies/presentation/diet_controller.dart';
import '../../profile_allergies/presentation/language_controller.dart';
import '../data/barcode_repository.dart';

import '../data/product_result.dart';

class ScanController extends Notifier<AsyncValue<ProductResult?>> {
  @override
  AsyncValue<ProductResult?> build() => const AsyncData<ProductResult?>(null);

  /// Lance la recherche produit pour l'EAN scanne.
  Future<void> scan(String ean) async {
    state = const AsyncLoading<ProductResult?>();

    state = await AsyncValue.guard<ProductResult?>(() async {
      final allergies = await ref.read(allergyControllerProvider.future);
      final diets = await ref.read(dietControllerProvider.future);
      final language = await ref.read(languageControllerProvider.future);
      return ref
          .read(barcodeRepositoryProvider)
          .lookup(ean, allergies, language, diets);
    });

    if (state.value != null) {
      final product = state.value!;
      await ref.read(parentScanAlertControllerProvider.notifier).recordIfNeeded(
        incompatible: product.riskLevel == 'DANGER',
        childDisplayName: 'Profil enfant',
        message:
            'Le produit scanné présente un risque ou une incompatibilité pour le profil enfant actif.',
      );
      ref.persistScanToHistory(() => ScanHistoryEntry.fromProductResult(product));
    }
  }

  void reset() => state = const AsyncData<ProductResult?>(null);
}

final scanControllerProvider =
    NotifierProvider<ScanController, AsyncValue<ProductResult?>>(
      ScanController.new,
    );
