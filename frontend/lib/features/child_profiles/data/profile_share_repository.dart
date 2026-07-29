import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'child_profile.dart';

/// Prefixe des codes QR revocables (UC-28). Le code ne contient qu'un jeton
/// opaque : le profil est recupere aupres du backend au moment du scan.
const String kShareTokenPrefix = 'MYAM_SHARE_V2:';

/// Partage genere pour un profil enfant.
class ProfileShare {
  const ProfileShare({required this.token, this.expiresAt});

  final String token;
  final DateTime? expiresAt;

  /// Contenu a encoder dans le code QR.
  String get qrPayload => '$kShareTokenPrefix$token';
}

class ProfileShareRepository {
  ProfileShareRepository(this._dio);

  final Dio _dio;

  /// Cree un partage revocable pour [childId]. [validityDays] null = illimite.
  Future<ProfileShare> create({
    required int childId,
    required String displayName,
    required List<String> allergies,
    required List<String> diets,
    int? validityDays,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/children/$childId/shares',
        data: {
          'displayName': displayName,
          'allergies': allergies,
          'diets': diets,
          'validityDays': validityDays,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Réponse vide ou invalide du serveur.');
      }

      final expiresAt = data['expires_at']?.toString();
      return ProfileShare(
        token: data['token'].toString(),
        expiresAt: expiresAt == null ? null : DateTime.tryParse(expiresAt),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Recupere le profil partage derriere un jeton scanne.
  Future<ChildProfileShareSnapshot> redeem(String token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/profile-shares/$token',
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Réponse vide ou invalide du serveur.');
      }

      return ChildProfileShareSnapshot(
        displayName: data['display_name']?.toString() ?? 'Profil enfant',
        allergies: _toStringList(data['allergies']),
        diets: _toStringList(data['diets']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static List<String> _toStringList(Object? value) {
    if (value is! List) return const <String>[];
    return value.map((item) => item.toString()).toList();
  }
}

final profileShareRepositoryProvider = Provider<ProfileShareRepository>((ref) {
  return ProfileShareRepository(ref.watch(dioProvider));
});
