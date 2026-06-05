import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_endpoints.dart';

/// Cle de stockage securise du token JWT.
///
/// Aucun ecran de login n'existe encore : la cle reste vide pour l'instant.
/// Quand l'auth (UC8) sera implementee, il suffira d'ecrire le token sous cette
/// cle apres le login — l'intercepteur ci-dessous l'ajoutera automatiquement.
const String authTokenKey = 'auth_token';

/// Stockage securise partage (Keychain iOS / Keystore Android).
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Client HTTP unique de l'application.
///
/// - baseUrl = [ApiEndpoints.baseUrl] (surchargé via `--dart-define=API_BASE_URL`).
/// - Intercepteur JWT "no-op" : lit le token dans le stockage securise et l'ajoute
///   en `Authorization: Bearer ...` s'il existe. Tant que l'auth n'est pas branchee,
///   il n'y a pas de token → l'intercepteur ne fait rien, sans aucune refonte a prevoir.
/// - Log des requetes en debug uniquement.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: authTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  return dio;
});
