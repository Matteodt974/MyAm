import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/barcode_repository.dart';

import '../data/product_result.dart';

class ScanController extends Notifier<AsyncValue<ProductResult?>> {
  @override
  AsyncValue<ProductResult?> build() => const AsyncData<ProductResult?>(null);

  Future<void> scan(String ean) async {
    state = const AsyncLoading<ProductResult?>();

    state = await AsyncValue.guard<ProductResult?>(
      () => ref.read(barcodeRepositoryProvider).lookup(ean),
    );
  }

  void reset() => state = const AsyncData<ProductResult?>(null);
}

final scanControllerProvider =
    NotifierProvider<ScanController, AsyncValue<ProductResult?>>(
      ScanController.new,
    );
