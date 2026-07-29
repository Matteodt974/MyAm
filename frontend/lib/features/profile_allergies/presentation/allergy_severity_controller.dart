import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../data/allergy_severity.dart';
import '../data/allergy_severity_local_store.dart';

/// Expose la severite configuree pour chaque allergene du profil actif (UC-13).
///
/// Les allergenes absents de la table prennent la valeur par defaut du profil :
/// severe pour un sous-profil enfant, moderee pour le compte principal.
class AllergySeverityController
    extends AsyncNotifier<Map<String, AllergySeverity>> {
  @override
  Future<Map<String, AllergySeverity>> build() {
    // watch (et non read) : la table doit etre rechargee quand le parent
    // bascule vers un autre sous-profil.
    final profileState = ref.watch(childProfileControllerProvider).value;
    final parentId = ref.watch(guardianIdProvider);
    if (parentId == null) {
      throw StateError('Utilisateur non authentifié');
    }
    final profileId = profileState?.activeProfileId ?? parentId;
    return ref.read(allergySeverityLocalStoreProvider).load(profileId);
  }

  bool get _isChildProfile {
    final profileState = ref.read(childProfileControllerProvider).value;
    final parentId = ref.read(guardianIdProvider);
    final activeId = profileState?.activeProfileId ?? parentId;
    return activeId != parentId;
  }

  /// Severite effective d'un allergene, defaut du profil compris.
  AllergySeverity severityOf(String allergy) {
    final configured = state.value?[allergy];
    if (configured != null) return configured;
    return AllergySeverity.defaultFor(isChildProfile: _isChildProfile);
  }

  Future<void> setSeverity(String allergy, AllergySeverity severity) async {
    final current = <String, AllergySeverity>{...?state.value};
    current[allergy] = severity;

    state = AsyncData(current);

    final profileId = _profileId();
    if (profileId == null) return;
    await ref.read(allergySeverityLocalStoreProvider).save(profileId, current);
  }

  /// Retire la severite d'un allergene supprime du profil.
  Future<void> forget(String allergy) async {
    final current = <String, AllergySeverity>{...?state.value};
    if (current.remove(allergy) == null) return;

    state = AsyncData(current);

    final profileId = _profileId();
    if (profileId == null) return;
    await ref.read(allergySeverityLocalStoreProvider).save(profileId, current);
  }

  int? _profileId() {
    final profileState = ref.read(childProfileControllerProvider).value;
    final parentId = ref.read(guardianIdProvider);
    if (parentId == null) return null;
    return profileState?.activeProfileId ?? parentId;
  }
}

final allergySeverityControllerProvider =
    AsyncNotifierProvider<
      AllergySeverityController,
      Map<String, AllergySeverity>
    >(AllergySeverityController.new);
