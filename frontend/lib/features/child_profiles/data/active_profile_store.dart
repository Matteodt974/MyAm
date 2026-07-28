import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

class ActiveProfileStore {
  ActiveProfileStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'active_profile_id';

  Future<int?> load() async {
    final value = await _storage.read(key: _key);
    return int.tryParse(value ?? '');
  }

  Future<void> save(int profileId) {
    return _storage.write(key: _key, value: profileId.toString());
  }
}

final activeProfileStoreProvider = Provider<ActiveProfileStore>((ref) {
  return ActiveProfileStore(ref.watch(secureStorageProvider));
});
