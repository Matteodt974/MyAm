import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  final int? statusCode;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;

    final status = response?.statusCode;

    final serverMessage = _extractServerMessage(response?.data);

    if (serverMessage != null && serverMessage.isNotEmpty) {
      return ApiException(serverMessage, statusCode: status);
    }

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
  String toString() => message;
}
