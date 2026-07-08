import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scan_history_entry.dart';
import '../data/scan_history_repository.dart';
import 'history_controller.dart';

/// Shared hook used by every scan controller (barcode, dish, label) to
/// persist a freshly produced [ScanHistoryEntry] and keep the History tab in
/// sync with it, without duplicating the save-then-refresh sequence in each
/// controller.
extension ScanHistoryPersistence on Ref {
  /// Builds and saves a history entry in the background, then invalidates
  /// [historyControllerProvider] so the History tab reflects the new scan.
  void persistScanToHistory(FutureOr<ScanHistoryEntry> Function() buildEntry) {
    unawaited(_persistScanToHistory(buildEntry));
  }

  Future<void> _persistScanToHistory(
    FutureOr<ScanHistoryEntry> Function() buildEntry,
  ) async {
    final entry = await buildEntry();
    await read(scanHistoryRepositoryProvider).save(entry);
    if (mounted) invalidate(historyControllerProvider);
  }
}
