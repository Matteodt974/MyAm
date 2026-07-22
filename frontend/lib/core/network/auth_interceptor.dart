import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  final Dio _authenticatedDio;
  final AuthRepository _authRepository;

  Completer<void>? _refreshCompleter;

  AuthInterceptor({
    required this._authenticatedDio,
    required this._authRepository,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authRepository.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Un autre refresh est déjà en cours : on attend qu'il finisse.
    if (_refreshCompleter != null) {
      try {
        await _refreshCompleter!.future;
      } catch (_) {
        handler.reject(err);
        return;
      }

      final token = await _authRepository.getAccessToken();
      if (token != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _authenticatedDio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      }

      handler.reject(err);
      return;
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await _authRepository.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.completeError(Exception('No refresh token'));
        await _authRepository.clearAuthData();
        handler.reject(err);
        return;
      }

      await _authRepository.refresh(refreshToken);
      _refreshCompleter!.complete();

      final newToken = await _authRepository.getAccessToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await _authenticatedDio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      }

      handler.reject(err);
    } catch (e) {
      _refreshCompleter!.completeError(e);
      await _authRepository.clearAuthData();
      handler.reject(err);
    } finally {
      _refreshCompleter = null;
    }
  }
}
