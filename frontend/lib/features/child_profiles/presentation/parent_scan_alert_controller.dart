import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/child_profile.dart';
import '../data/parent_scan_alert_store.dart';
import 'child_profile_controller.dart';

class ParentScanAlertController extends AutoDisposeNotifier<List<ParentScanAlert>> {
  @override
  List<ParentScanAlert> build() {
    Future<void>.microtask(() => load());
    return const <ParentScanAlert>[];
  }

  Future<void> load() async {
    final guardianId = ref.read(guardianIdProvider);
    if (guardianId == null) return;

    final alerts = await ref.read(parentScanAlertStoreProvider).load(guardianId);
    state = alerts;
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
    NotifierProvider.autoDispose<ParentScanAlertController, List<ParentScanAlert>>(
      ParentScanAlertController.new,
    );
