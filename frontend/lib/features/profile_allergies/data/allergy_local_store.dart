import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

/// Persistance LOCALE de la liste d'allergies (aucun backend pour l'instant).
///
/// Stockee en JSON dans le stockage securise de l'appareil. Le jour ou l'auth +
/// l'endpoint `/v1/user/profile/allergies` (UC6) existeront, il suffira de
/// remplacer cette implementation par un repository reseau — l'UI ne bouge pas.
class AllergyLocalStore {
  AllergyLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'user_allergies';

  Future<List<String>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return <String>[];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Future<void> save(List<String> allergies) async {
    await _storage.write(key: _key, value: jsonEncode(allergies));
  }
}

final allergyLocalStoreProvider = Provider<AllergyLocalStore>((ref) {
  return AllergyLocalStore(ref.watch(secureStorageProvider));
});
