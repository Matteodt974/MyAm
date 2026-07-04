import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

class DietLocalStore {
  DietLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'user_diets';

  Future<List<String>> load() async {
    final raw = await _storage.read(key: _key);

    if (raw == null || raw.isEmpty) return <String>[];

    final decoded = jsonDecode(raw);

    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Future<void> save(List<String> diets) async {
    await _storage.write(key: _key, value: jsonEncode(diets));
  }
}

final dietLocalStoreProvider = Provider<DietLocalStore>((ref) {
  return DietLocalStore(ref.watch(secureStorageProvider));
});