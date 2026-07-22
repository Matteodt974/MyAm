class ApiEndpoints {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _backendUrl = String.fromEnvironment('BACKEND_URL');
  static const String _backendHost = String.fromEnvironment('BACKEND_HOST');
  static const String _backendPort = String.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: '8545',
  );
  static const String _backendScheme = String.fromEnvironment(
    'BACKEND_SCHEME',
    defaultValue: 'http',
  );

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _normalize(_apiBaseUrl);
    if (_backendUrl.isNotEmpty) return _normalize(_backendUrl);
    if (_backendHost.isNotEmpty) {
      return _normalize('$_backendScheme://$_backendHost:$_backendPort');
    }
    return 'http://10.0.2.2:8545';
  }

  static String _normalize(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static const String health = '/health';

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String scanBarcode = '/v1/scan/barcode';

  static const String scanDish = '/v1/scan/dish';

  static const String scanLabel = '/v1/label/translate-and-structure';
}
