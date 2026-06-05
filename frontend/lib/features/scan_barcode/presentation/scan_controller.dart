import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/barcode_repository.dart';
import '../data/product_result.dart';

/// Etat du scan code-barres : `null` = inactif, loading pendant l'appel API,
/// data = fiche produit, error = message d'erreur (via [AsyncValue]).
class ScanController extends Notifier<AsyncValue<ProductResult?>> {
  @override
  AsyncValue<ProductResult?> build() => const AsyncData<ProductResult?>(null);

  /// Lance la recherche produit pour l'EAN scanne.
  Future<void> scan(String ean) async {
    state = const AsyncLoading<ProductResult?>();
    state = await AsyncValue.guard<ProductResult?>(
      () => ref.read(barcodeRepositoryProvider).lookup(ean),
    );
  }

  /// Reinitialise l'etat (apres fermeture de la fiche resultat).
  void reset() => state = const AsyncData<ProductResult?>(null);
}

final scanControllerProvider =
    NotifierProvider<ScanController, AsyncValue<ProductResult?>>(
  ScanController.new,
);
