import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;
import 'allergy_severity.dart';

/// Stockage local des severites par allergene (UC-13).
///
/// Volontairement separe de [AllergyLocalStore] : la liste d'allergenes est le
/// format transmis au backend lors des scans, alors que la severite reste une
/// donnee d'affichage locale. Les garder distincts evite de migrer les profils
/// deja enregistres sur l'appareil.
class AllergySeverityLocalStore {
  AllergySeverityLocalStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<Map<String, AllergySeverity>> load(int profileId) async {
    final raw = await _storage.read(key: _key(profileId));
    if (raw == null || raw.isEmpty) return <String, AllergySeverity>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, AllergySeverity>{};

      return decoded.map(
        (key, value) =>
            MapEntry(key.toString(), AllergySeverity.fromStorage(value)),
      );
    } on FormatException {
      return <String, AllergySeverity>{};
    }
  }

  Future<void> save(
    int profileId,
    Map<String, AllergySeverity> severities,
  ) async {
    await _storage.write(
      key: _key(profileId),
      value: jsonEncode(
        severities.map((key, value) => MapEntry(key, value.storageValue)),
      ),
    );
  }

  String _key(int profileId) => 'user_allergy_severities_$profileId';
}

final allergySeverityLocalStoreProvider = Provider<AllergySeverityLocalStore>((
  ref,
) {
  return AllergySeverityLocalStore(ref.watch(secureStorageProvider));
});
