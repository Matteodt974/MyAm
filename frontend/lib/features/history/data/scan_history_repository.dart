import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scan_history_database.dart';
import 'scan_history_entry.dart';

/// Simple value object describing how to filter scan history entries.
class HistoryFilter {
  const HistoryFilter({
    this.from,
    this.to,
    this.types,
    this.riskLevels,
    this.allergen,
  });

  final DateTime? from;
  final DateTime? to;
  final List<ScanType>? types;
  final List<String>? riskLevels;
  final String? allergen;
}

/// Repository that exposes a fire-and-forget safe API around the local scan
/// history database.
class ScanHistoryRepository {
  ScanHistoryRepository(this._db);

  final ScanHistoryDatabase _db;

  /// Persists [entry] without ever surfacing an error to callers.
  ///
  /// History persistence is a best-effort side effect: if SQLite is unavailable
  /// or the write fails, the error is logged and the UI flow continues.
  Future<void> save(ScanHistoryEntry entry) async {
    try {
      await _db.insert(entry);
    } catch (e, st) {
      debugPrint('Failed to save scan history entry: $e\n$st');
    }
  }

  /// Loads persisted entries, optionally filtered.
  Future<List<ScanHistoryEntry>> load({HistoryFilter? filter}) async {
    if (filter == null) {
      return _db.getAll();
    }
    return _db.getFiltered(
      from: filter.from,
      to: filter.to,
      types: filter.types,
      riskLevels: filter.riskLevels,
      allergen: filter.allergen,
    );
  }

  /// Deletes the entry with the given [id].
  Future<void> delete(int id) => _db.delete(id);

  /// Deletes all entries.
  Future<void> clear() => _db.deleteAll();
}

final scanHistoryDatabaseProvider = Provider<ScanHistoryDatabase>((ref) {
  return ScanHistoryDatabase.instance;
});

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return ScanHistoryRepository(ref.watch(scanHistoryDatabaseProvider));
});
