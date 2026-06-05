import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'dish_result.dart';

/// Acces a l'endpoint `POST /v1/scan/dish` (UC5, stretch).
///
/// Envoie la photo en multipart sous le champ **`image`** (contrat backend).
class DishRepository {
  DishRepository(this._dio);

  final Dio _dio;

  Future<DishResult> analyze(File image) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.uri.pathSegments.isNotEmpty
              ? image.uri.pathSegments.last
              : 'dish.jpg',
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.scanDish,
        data: formData,
      );
      return DishResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final dishRepositoryProvider = Provider<DishRepository>((ref) {
  return DishRepository(ref.watch(dioProvider));
});
