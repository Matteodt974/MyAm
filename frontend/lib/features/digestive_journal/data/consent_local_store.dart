import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

class ConsentLocalStore {
  ConsentLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'digestive_journal_consent';

  Future<bool> load() async {
    final raw = await _storage.read(key: _key);
    return raw == 'true';
  }

  Future<void> save(bool consented) async {
    await _storage.write(key: _key, value: consented.toString());
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}

final consentLocalStoreProvider = Provider<ConsentLocalStore>((ref) {
  return ConsentLocalStore(ref.watch(secureStorageProvider));
});
