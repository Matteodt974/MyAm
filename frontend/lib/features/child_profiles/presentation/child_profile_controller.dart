import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/active_profile_store.dart';
import '../data/child_profile.dart';
import '../data/child_profile_repository.dart';

const _configuredParentId = int.fromEnvironment(
  'PARENT_USER_ID',
  defaultValue: 1,
);

// À remplacer par l'identifiant extrait du JWT lorsque l'authentification
// exposera l'utilisateur connecté.
final parentUserIdProvider = Provider<int>((ref) => _configuredParentId);

class ChildProfileState {
  const ChildProfileState({
    required this.profiles,
    required this.activeProfileId,
  });

  final List<ChildProfile> profiles;
  final int activeProfileId;

  ChildProfile get activeProfile => profiles.firstWhere(
    (profile) => profile.id == activeProfileId,
    orElse: () => profiles.first,
  );

  ChildProfileState copyWith({
    List<ChildProfile>? profiles,
    int? activeProfileId,
  }) {
    return ChildProfileState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
    );
  }
}

class ChildProfileController extends AsyncNotifier<ChildProfileState> {
  @override
  Future<ChildProfileState> build() async {
    final guardianId = ref.watch(parentUserIdProvider);
    final children = await ref
        .read(childProfileRepositoryProvider)
        .list(guardianId);
    final profiles = [ChildProfile.parent(guardianId), ...children];
    final storedId = await ref.read(activeProfileStoreProvider).load();
    final activeId = profiles.any((profile) => profile.id == storedId)
        ? storedId!
        : guardianId;

    return ChildProfileState(profiles: profiles, activeProfileId: activeId);
  }

  Future<void> createChild(String displayName) async {
    final current = state.value;
    if (current == null) return;

    final guardianId = ref.read(parentUserIdProvider);
    final child = await ref
        .read(childProfileRepositoryProvider)
        .create(guardianId, displayName.trim());
    final next = current.copyWith(
      profiles: [...current.profiles, child],
      activeProfileId: child.id,
    );
    state = AsyncData(next);
    await ref.read(activeProfileStoreProvider).save(child.id);
  }

  Future<void> renameChild(int childId, String displayName) async {
    final current = state.value;
    if (current == null) return;

    final guardianId = ref.read(parentUserIdProvider);
    final updated = await ref
        .read(childProfileRepositoryProvider)
        .update(guardianId, childId, displayName.trim());
    final profiles = current.profiles
        .map((profile) => profile.id == childId ? updated : profile)
        .toList();
    state = AsyncData(current.copyWith(profiles: profiles));
  }

  Future<void> deleteChild(int childId) async {
    final current = state.value;
    if (current == null) return;

    final guardianId = ref.read(parentUserIdProvider);
    await ref.read(childProfileRepositoryProvider).delete(guardianId, childId);
    final profiles = current.profiles
        .where((profile) => profile.id != childId)
        .toList();
    final activeId = current.activeProfileId == childId
        ? guardianId
        : current.activeProfileId;
    state = AsyncData(
      current.copyWith(profiles: profiles, activeProfileId: activeId),
    );
    await ref.read(activeProfileStoreProvider).save(activeId);
  }

  Future<void> select(int profileId) async {
    final current = state.value;
    if (current == null ||
        !current.profiles.any((profile) => profile.id == profileId)) {
      return;
    }

    state = AsyncData(current.copyWith(activeProfileId: profileId));
    await ref.read(activeProfileStoreProvider).save(profileId);
  }
}

final childProfileControllerProvider =
    AsyncNotifierProvider<ChildProfileController, ChildProfileState>(
      ChildProfileController.new,
    );
