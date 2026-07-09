import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'label_result.dart';

class LabelRepository {
  LabelRepository(this._dio);

  final Dio _dio;

  /// Envoie le texte OCR au backend pour detection de langue, traduction
  /// et structuration en liste d'ingredients.
  ///
  /// Toute erreur reseau/HTTP est convertie en [ApiException] lisible.
  Future<LabelResult> analyze(
    String text,
    String language,
    List<String> allergies,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.scanLabel,
        data: {'text': text, 'language': language, 'allergies': allergies},
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
       ),
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException('Réponse vide ou invalide du serveur.');
      }

      return LabelResult.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final labelRepositoryProvider = Provider<LabelRepository>((ref) {
  return LabelRepository(ref.watch(dioProvider));
});
