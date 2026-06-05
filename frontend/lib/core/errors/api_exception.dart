import 'package:dio/dio.dart';

/// Exception applicative unifiee pour toute la couche reseau.
///
/// On ne laisse JAMAIS remonter une [DioException] brute jusqu'a l'UI : les
/// repositories la convertissent en [ApiException] via [ApiException.fromDio],
/// avec un message FR lisible et le code HTTP eventuel.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Traduit une [DioException] en message utilisateur.
  ///
  /// Le backend renvoie ses erreurs sous la forme `{"detail": "..."}` (FastAPI)
  /// ou `{"message": "..."}` / `{"error": "..."}` (Spring). On essaie de lire ce
  /// champ avant de retomber sur un message generique base sur le code HTTP.
  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final status = response?.statusCode;

    // 1) Message explicite renvoye par le backend.
    final serverMessage = _extractServerMessage(response?.data);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ApiException(serverMessage, statusCode: status);
    }

    // 2) Erreurs de transport (pas de reponse HTTP).
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Délai dépassé. Vérifie ta connexion.');
      case DioExceptionType.connectionError:
        return const ApiException(
          'Impossible de joindre le serveur. Est-il démarré ?',
        );
      case DioExceptionType.cancel:
        return const ApiException('Requête annulée.');
      default:
        break;
    }

    // 3) Messages generiques par code HTTP.
    switch (status) {
      case 400:
        return ApiException('Requête invalide.', statusCode: status);
      case 404:
        return ApiException('Produit introuvable.', statusCode: status);
      case 502:
        return ApiException(
          'Service externe indisponible. Réessaie plus tard.',
          statusCode: status,
        );
      default:
        return ApiException(
          'Une erreur est survenue${status != null ? ' ($status)' : ''}.',
          statusCode: status,
        );
    }
  }

  static String? _extractServerMessage(Object? data) {
    if (data is Map) {
      for (final key in const ['detail', 'message', 'error']) {
        final value = data[key];
        if (value is String) return value;
      }
    }
    return null;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
