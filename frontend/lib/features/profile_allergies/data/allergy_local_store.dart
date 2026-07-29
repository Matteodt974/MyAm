import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

class AllergyLocalStore {
  AllergyLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _legacyKey = 'user_allergies';

  Future<List<String>> load(int profileId, {required bool isParent}) async {
    var raw = await _storage.read(key: _key(profileId));
    if ((raw == null || raw.isEmpty) && isParent) {
      raw = await _storage.read(key: _legacyKey);
    }

    if (raw == null || raw.isEmpty) return <String>[];

    final decoded = jsonDecode(raw);

    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Future<void> save(int profileId, List<String> allergies) async {
    await _storage.write(key: _key(profileId), value: jsonEncode(allergies));
  }

  String _key(int profileId) => 'user_allergies_$profileId';
}

final allergyLocalStoreProvider = Provider<AllergyLocalStore>((ref) {
  return AllergyLocalStore(ref.watch(secureStorageProvider));
});
