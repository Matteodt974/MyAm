import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart' show secureStorageProvider;

class ParentScanAlert {
  const ParentScanAlert({
    required this.id,
    required this.childProfileId,
    required this.childDisplayName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final int childProfileId;
  final String childDisplayName;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_profile_id': childProfileId,
      'child_display_name': childDisplayName,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ParentScanAlert.fromJson(Map<String, dynamic> json) {
    return ParentScanAlert(
      id: json['id']?.toString() ?? '',
      childProfileId: int.tryParse(json['child_profile_id']?.toString() ?? '') ?? 0,
      childDisplayName: json['child_display_name']?.toString() ?? 'Profil enfant',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

abstract class ParentScanAlertStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureParentScanAlertStorage implements ParentScanAlertStorage {
  FlutterSecureParentScanAlertStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class ParentScanAlertStore {
  ParentScanAlertStore([ParentScanAlertStorage? storage])
    : _storage = storage ?? FlutterSecureParentScanAlertStorage(FlutterSecureStorage());

  final ParentScanAlertStorage _storage;

  static const String _prefix = 'parent_scan_alerts_';

  Future<List<ParentScanAlert>> load(int guardianId) async {
    final raw = await _storage.read(_key(guardianId));
    if (raw == null || raw.isEmpty) return const <ParentScanAlert>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <ParentScanAlert>[];

    return decoded
        .whereType<Map>()
        .map((item) => ParentScanAlert.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> add(int guardianId, ParentScanAlert alert) async {
    final alerts = await load(guardianId);
    final next = [
      ...alerts.where((item) => item.id != alert.id),
      alert,
    ];
    await _storage.write(
      _key(guardianId),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> dismiss(int guardianId, String alertId) async {
    final alerts = await load(guardianId);
    final next = alerts.where((item) => item.id != alertId).toList();

    if (next.isEmpty) {
      await _storage.delete(_key(guardianId));
      return;
    }

    await _storage.write(
      _key(guardianId),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  String _key(int guardianId) => '$_prefix$guardianId';
}

final parentScanAlertStoreProvider = Provider<ParentScanAlertStore>((ref) {
  return ParentScanAlertStore(
    FlutterSecureParentScanAlertStorage(ref.watch(secureStorageProvider)),
  );
});
