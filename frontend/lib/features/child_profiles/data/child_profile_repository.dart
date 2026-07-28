import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'child_profile.dart';

class ChildProfileRepository {
  ChildProfileRepository(this._dio);

  final Dio _dio;

  Future<List<ChildProfile>> list(int guardianId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.childProfiles(guardianId),
      );
      return (response.data ?? const [])
          .map(
            (json) =>
                ChildProfile.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChildProfile> create(int guardianId, String displayName) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.childProfiles(guardianId),
        data: {'displayName': displayName},
      );
      return ChildProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChildProfile> update(
    int guardianId,
    int childId,
    String displayName,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.childProfile(guardianId, childId),
        data: {'displayName': displayName},
      );
      return ChildProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> delete(int guardianId, int childId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.childProfile(guardianId, childId));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final childProfileRepositoryProvider = Provider<ChildProfileRepository>((ref) {
  return ChildProfileRepository(ref.watch(dioProvider));
});
