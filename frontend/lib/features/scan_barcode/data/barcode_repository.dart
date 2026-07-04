import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';

import '../../../core/errors/api_exception.dart';

import '../../../core/network/dio_client.dart';

import 'product_result.dart';

class BarcodeRepository {
  BarcodeRepository(this._dio);

  final Dio _dio;

  /// Interroge le backend pour l'EAN scanne et renvoie la fiche produit.
  ///
  /// Toute erreur reseau/HTTP est convertie en [ApiException] lisible.
  Future<ProductResult> lookup(
    String ean,
    List<String> allergies,
    String language,
    List<String> diets,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.scanBarcode,
        data: {
          'ean': ean,
          'allergies': allergies,
          'language': language,
          'diets': diets,
        },
      );

      return ProductResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final barcodeRepositoryProvider = Provider<BarcodeRepository>((ref) {
  return BarcodeRepository(ref.watch(dioProvider));
});
