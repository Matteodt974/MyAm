import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

class TrustedItemLocalStore {
  TrustedItemLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'trusted_items';

  Future<List<TrustedItem>> load() async {
    final raw = await _storage.read(key: _key);

    if (raw == null || raw.isEmpty) return <TrustedItem>[];

    final decoded = jsonDecode(raw);

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => TrustedItem.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return <TrustedItem>[];
  }

  Future<void> save(List<TrustedItem> items) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}

class TrustedItem {
  const TrustedItem({
    String? id,
    required this.ean,
    this.name,
    this.brands,
    this.nutriscore,
  }) : id = id ?? ean;

  final String id;

  final String ean;
  final String? name;
  final String? brands;
  final String? nutriscore;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ean': ean,
    'name': name,
    'brands': brands,
    'nutriscore': nutriscore,
  };

  factory TrustedItem.fromJson(Map<String, dynamic> json) {
    final ean = json['ean']?.toString() ?? '';
    return TrustedItem(
      id: json['id']?.toString(),
      ean: ean,
      name: json['name']?.toString(),
      brands: json['brands']?.toString(),
      nutriscore: json['nutriscore']?.toString(),
    );
  }
}

final trustedItemLocalStoreProvider = Provider<TrustedItemLocalStore>((ref) {
  return TrustedItemLocalStore(ref.watch(secureStorageProvider));
});
