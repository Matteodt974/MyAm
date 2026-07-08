import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile_allergies/presentation/language_controller.dart';
import '../data/barcode_repository.dart';

import '../data/product_result.dart';

class ScanController extends Notifier<AsyncValue<ProductResult?>> {
  @override
  AsyncValue<ProductResult?> build() => const AsyncData<ProductResult?>(null);

  /// Lance la recherche produit pour l'EAN scanne.
  Future<void> scan(String ean, List<String> allergies) async {
    state = const AsyncLoading<ProductResult?>();

    state = await AsyncValue.guard<ProductResult?>(() async {
      final language = await ref.read(languageControllerProvider.future);
      return ref
          .read(barcodeRepositoryProvider)
          .lookup(ean, allergies, language);
    });
  }

  void reset() => state = const AsyncData<ProductResult?>(null);
}

final scanControllerProvider =
    NotifierProvider<ScanController, AsyncValue<ProductResult?>>(
      ScanController.new,
    );
