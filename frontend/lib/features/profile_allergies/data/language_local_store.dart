import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/languages.dart';
import '../../../core/network/dio_client.dart' show secureStorageProvider;

class LanguageLocalStore {
  LanguageLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'preferred_output_language';

  Future<String> load() async {
    final raw = await _storage.read(key: _key);

    return raw == null || raw.isEmpty ? defaultLanguage : raw;
  }

  Future<void> save(String language) async {
    await _storage.write(key: _key, value: language);
  }
}

final languageLocalStoreProvider = Provider<LanguageLocalStore>((ref) {
  return LanguageLocalStore(ref.watch(secureStorageProvider));
});
