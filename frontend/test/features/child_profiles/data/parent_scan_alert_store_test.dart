import 'package:flutter_test/flutter_test.dart';
import 'package:myam/features/child_profiles/data/parent_scan_alert_store.dart';

class FakeParentScanAlertStorage implements ParentScanAlertStorage {
  final Map<String, String> _entries = {};

  @override
  Future<String?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, String value) async {
    _entries[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _entries.remove(key);
  }
}

void main() {
  test('persists and dismisses guardian alerts', () async {
    final storage = FakeParentScanAlertStorage();
    final store = ParentScanAlertStore(storage);

    final alert = ParentScanAlert(
      id: 'alert-1',
      childProfileId: 42,
      childDisplayName: 'Léa',
      message: 'Léa a scanné un produit incompatible.',
      createdAt: DateTime(2026, 7, 29),
    );

    await store.add(7, alert);
    expect(await store.load(7), hasLength(1));

    await store.dismiss(7, alert.id);
    expect(await store.load(7), isEmpty);
  });
}
