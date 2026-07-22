import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_endpoints.dart';
import 'auth_response.dart';

const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';
const String _accessTokenExpiryKey = 'access_token_expiry';
const String _refreshTokenExpiryKey = 'refresh_token_expiry';
const String _userIdKey = 'user_id';
const String _userEmailKey = 'user_email';
const String _userDisplayNameKey = 'user_display_name';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<void> register(String email, String password, String displayName) async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authRegister,
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );
    final auth = AuthResponse.fromJson(response.data!);
    await _saveAuthResponse(auth);
    return auth;
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': refreshToken},
    );
    final auth = AuthResponse.fromJson(response.data!);
    await _saveAuthResponse(auth);
    return auth;
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _dio.post(
          ApiEndpoints.authLogout,
          data: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // On efface les tokens localement même si le backend échoue.
      }
    }
    await clearAuthData();
  }

  Future<String?> getAccessToken() async {
    final expiry = await _storage.read(key: _accessTokenExpiryKey);
    if (expiry == null) return null;

    final expiryDate = DateTime.tryParse(expiry);
    if (expiryDate == null) return null;

    // Si le token expire dans moins de 60 secondes, on considère qu'il est expiré.
    if (expiryDate.isBefore(DateTime.now().add(const Duration(seconds: 60)))) {
      return null;
    }

    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final expiry = await _storage.read(key: _refreshTokenExpiryKey);
    if (expiry == null) return null;

    final expiryDate = DateTime.tryParse(expiry);
    if (expiryDate == null) return null;

    if (expiryDate.isBefore(DateTime.now())) {
      return null;
    }

    return _storage.read(key: _refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    if (accessToken != null) return true;

    final refreshToken = await getRefreshToken();
    return refreshToken != null;
  }

  Future<UserDto?> getCurrentUser() async {
    final id = await _storage.read(key: _userIdKey);
    final email = await _storage.read(key: _userEmailKey);
    final displayName = await _storage.read(key: _userDisplayNameKey);

    if (id == null || email == null || displayName == null) return null;

    return UserDto(
      id: int.parse(id),
      email: email,
      displayName: displayName,
    );
  }

  Future<void> _saveAuthResponse(AuthResponse auth) async {
    final now = DateTime.now();
    final accessExpiry = now.add(Duration(seconds: auth.accessExpiresIn));
    final refreshExpiry = now.add(Duration(seconds: auth.refreshExpiresIn));

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: auth.accessToken),
      _storage.write(key: _refreshTokenKey, value: auth.refreshToken),
      _storage.write(key: _accessTokenExpiryKey, value: accessExpiry.toIso8601String()),
      _storage.write(key: _refreshTokenExpiryKey, value: refreshExpiry.toIso8601String()),
      _storage.write(key: _userIdKey, value: auth.user.id.toString()),
      _storage.write(key: _userEmailKey, value: auth.user.email),
      _storage.write(key: _userDisplayNameKey, value: auth.user.displayName),
    ]);
  }

  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessTokenExpiryKey),
      _storage.delete(key: _refreshTokenExpiryKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userEmailKey),
      _storage.delete(key: _userDisplayNameKey),
    ]);
  }
}
