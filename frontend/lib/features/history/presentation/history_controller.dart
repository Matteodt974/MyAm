import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../data/scan_history_entry.dart';
import '../data/scan_history_export.dart';
import '../data/scan_history_repository.dart';

/// Riverpod controller for the scan history screen.
class HistoryController extends AsyncNotifier<List<ScanHistoryEntry>> {
  /// Active filter applied to history loads. Kept so that refresh() can reload
  /// with the same criteria the user previously selected.
  HistoryFilter? _currentFilter;

  @override
  Future<List<ScanHistoryEntry>> build() {
    ref.watch(childProfileControllerProvider);
    return _load();
  }

  Future<List<ScanHistoryEntry>> _load() {
    final profileId = _activeProfileId();
    if (profileId == null) return Future.value(const <ScanHistoryEntry>[]);
    return ref
        .read(scanHistoryRepositoryProvider)
        .load(profileId, filter: _currentFilter);
  }

  int? _activeProfileId() {
    final profileState = ref.read(childProfileControllerProvider).value;
    final parentId = ref.read(guardianIdProvider);
    if (parentId == null) return null;
    return profileState?.activeProfileId ?? parentId;
  }

  /// Reloads the history while preserving the current filter.
  Future<void> refresh() async {
    state = const AsyncLoading<List<ScanHistoryEntry>>();
    state = await AsyncValue.guard<List<ScanHistoryEntry>>(_load);
  }

  /// Applies a new filter and reloads the history.
  Future<void> applyFilter(HistoryFilter filter) async {
    _currentFilter = filter;
    await refresh();
  }

  /// Clears any active filter and reloads the full history.
  Future<void> clearFilter() async {
    _currentFilter = null;
    await refresh();
  }

  /// Deletes a single history entry and refreshes the list.
  Future<void> delete(int id) async {
    final profileId = _activeProfileId();
    if (profileId == null) return;
    await ref.read(scanHistoryRepositoryProvider).delete(id, profileId);
    await refresh();
  }

  /// Deletes every history entry and refreshes the list.
  Future<void> clearAll() async {
    final profileId = _activeProfileId();
    if (profileId == null) return;
    await ref.read(scanHistoryRepositoryProvider).clear(profileId);
    await refresh();
  }

  /// Exports the currently loaded entries (filtered or not) as a CSV file.
  /// Does nothing while the controller is loading or in error state.
  Future<void> exportCsv() async {
    final entries = state.value;
    if (entries == null) return;

    await ScanHistoryExport().exportCsv(entries);
  }
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, List<ScanHistoryEntry>>(
      HistoryController.new,
    );
