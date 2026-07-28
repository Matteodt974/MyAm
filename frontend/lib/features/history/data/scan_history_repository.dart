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

  /// Persists [entry] under [profileId] without ever surfacing an error to
  /// callers.
  ///
  /// History persistence is a best-effort side effect: if SQLite is unavailable
  /// or the write fails, the error is logged and the UI flow continues.
  Future<void> save(ScanHistoryEntry entry, int profileId) async {
    try {
      await _db.insert(entry, profileId);
    } catch (e, st) {
      debugPrint('Failed to save scan history entry: $e\n$st');
    }
  }

  /// Loads entries belonging to [profileId], optionally filtered.
  Future<List<ScanHistoryEntry>> load(
    int profileId, {
    HistoryFilter? filter,
  }) async {
    if (filter == null) {
      return _db.getAll(profileId);
    }
    return _db.getFiltered(
      profileId: profileId,
      from: filter.from,
      to: filter.to,
      types: filter.types,
      riskLevels: filter.riskLevels,
      allergen: filter.allergen,
    );
  }

  /// Deletes the entry with the given [id] belonging to [profileId].
  Future<void> delete(int id, int profileId) => _db.delete(id, profileId);

  /// Deletes every entry belonging to [profileId].
  Future<void> clear(int profileId) => _db.deleteAll(profileId);
}

final scanHistoryDatabaseProvider = Provider<ScanHistoryDatabase>((ref) {
  return ScanHistoryDatabase.instance;
});

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return ScanHistoryRepository(ref.watch(scanHistoryDatabaseProvider));
});
