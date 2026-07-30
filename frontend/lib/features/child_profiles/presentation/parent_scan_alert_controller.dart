import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/child_profile.dart';
import '../data/parent_scan_alert_store.dart';
import 'child_profile_controller.dart';

class ParentScanAlertController extends AsyncNotifier<List<ParentScanAlert>> {
  @override
  Future<List<ParentScanAlert>> build() async {
    return _loadAlerts();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadAlerts());
  }

  Future<List<ParentScanAlert>> _loadAlerts() async {
    final guardianId = ref.read(guardianIdProvider);
    if (guardianId == null) return const <ParentScanAlert>[];

    return ref.read(parentScanAlertStoreProvider).load(guardianId);
  }

  Future<void> recordIfNeeded({
    required bool incompatible,
    required String childDisplayName,
    required String message,
  }) async {
    if (!incompatible) return;

    final guardianId = ref.read(guardianIdProvider);
    if (guardianId == null) return;

    final childProfileState = ref.read(childProfileControllerProvider).value;
    final activeChild = childProfileState?.profiles.firstWhere(
      (profile) => profile.id == childProfileState.activeProfileId && profile.isChild,
      orElse: () => const ChildProfile(id: 0, displayName: 'Profil enfant', isChild: true),
    );

    final alert = ParentScanAlert(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      childProfileId: activeChild?.id ?? 0,
      childDisplayName: activeChild?.displayName ?? childDisplayName,
      message: message,
      createdAt: DateTime.now(),
    );

    await ref.read(parentScanAlertStoreProvider).add(guardianId, alert);
    await load();
  }

  Future<void> dismiss(String alertId) async {
    final guardianId = ref.read(guardianIdProvider);
    if (guardianId == null) return;

    await ref.read(parentScanAlertStoreProvider).dismiss(guardianId, alertId);
    await load();
  }
}

final parentScanAlertControllerProvider =
    AsyncNotifierProvider.autoDispose<ParentScanAlertController, List<ParentScanAlert>>(
      ParentScanAlertController.new,
    );
