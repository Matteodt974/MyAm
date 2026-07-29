import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Allergies et regimes d'un profil tels que le serveur les connait (UC-13B).
class ProfilePreferences {
  const ProfilePreferences({required this.allergies, required this.diets});

  factory ProfilePreferences.fromJson(Map<String, dynamic> json) {
    return ProfilePreferences(
      allergies: _stringList(json['allergies']),
      diets: _stringList(json['diets']),
    );
  }

  final List<String> allergies;
  final List<String> diets;

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw.map((e) => e.toString()).toList()..sort();
  }
}

/// Source de verite serveur du profil, ce qui permet de le retrouver sur un
/// autre appareil. Couvre le compte lui-meme comme ses sous-profils enfants.
class ProfilePreferencesRepository {
  ProfilePreferencesRepository(this._dio);

  final Dio _dio;

  Future<ProfilePreferences> fetch(int profileId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.profilePreferences(profileId),
      );
      return ProfilePreferences.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ProfilePreferences> replace(
    int profileId, {
    required List<String> allergies,
    required List<String> diets,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.profilePreferences(profileId),
        data: {'allergies': allergies, 'diets': diets},
      );
      return ProfilePreferences.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final profilePreferencesRepositoryProvider =
    Provider<ProfilePreferencesRepository>((ref) {
      return ProfilePreferencesRepository(ref.watch(dioProvider));
    });
