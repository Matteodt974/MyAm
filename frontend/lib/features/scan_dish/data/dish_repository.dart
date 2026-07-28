import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'dish_result.dart';

class DishRepository {
  DishRepository(this._dio);

  final Dio _dio;

  Future<DishResult> analyze(
    File image,
    String language,
    List<String> diets,
  ) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.uri.pathSegments.isNotEmpty
              ? image.uri.pathSegments.last
              : 'dish.jpg',
        ),
        'language': language,
        'diets': diets.join(','),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.scanDish,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
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
