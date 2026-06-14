import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';

import '../../../core/errors/api_exception.dart';

import '../../../core/network/dio_client.dart';

import 'product_result.dart';

class BarcodeRepository {
  BarcodeRepository(this._dio);

  final Dio _dio;

  Future<ProductResult> lookup(String ean) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.scanBarcode,
        data: {'ean': ean},
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
