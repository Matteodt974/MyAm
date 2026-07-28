import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'intolerance_report.dart';

class IntoleranceAnalysisRepository {
  IntoleranceAnalysisRepository(this._dio);

  final Dio _dio;

  /// Lance l'analyse d'intolerance (UC-26) pour le journal alimentaire fourni.
  ///
  /// Les episodes du journal digestif sont charges cote serveur a partir du
  /// compte authentifie.
  Future<IntoleranceReport> analyze(List<FoodItemPayload> foodItems) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.analysisIntolerance,
        data: {'foodItems': foodItems.map((item) => item.toJson()).toList()},
      );

      return IntoleranceReport.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final intoleranceAnalysisRepositoryProvider =
    Provider<IntoleranceAnalysisRepository>(
      (ref) => IntoleranceAnalysisRepository(ref.watch(dioProvider)),
    );
