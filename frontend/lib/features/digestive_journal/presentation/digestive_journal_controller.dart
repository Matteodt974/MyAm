import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/digestive_entry.dart';
import '../data/digestive_journal_repository.dart';
import '../../child_profiles/presentation/child_profile_controller.dart';

/// Controleur du journal digestif (UC-23).
class DigestiveJournalController extends AsyncNotifier<List<DigestiveEntry>> {
  @override
  Future<List<DigestiveEntry>> build() {
    final profileId = ref.watch(activeProfileIdProvider);
    if (profileId == null) return Future.value(const <DigestiveEntry>[]);
    return _load(profileId);
  }

  Future<List<DigestiveEntry>> _load(int profileId) =>
      ref.read(digestiveJournalRepositoryProvider).list(profileId: profileId);

  Future<void> refresh() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    state = const AsyncLoading<List<DigestiveEntry>>();
    state = await AsyncValue.guard<List<DigestiveEntry>>(
      () => _load(profileId),
    );
  }

  /// Ajoute une entree puis recharge la liste.
  ///
  /// Les erreurs remontent a l'appelant pour qu'il affiche le message du
  /// backend dans le formulaire de saisie.
  Future<void> addEntry({
    required int bristolType,
    required DateTime occurredAt,
    String? notes,
  }) async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null) return;
    await ref
        .read(digestiveJournalRepositoryProvider)
        .create(
          profileId: profileId,
          bristolType: bristolType,
          occurredAt: occurredAt,
          notes: notes,
        );
    await refresh();
  }
}

final digestiveJournalControllerProvider =
    AsyncNotifierProvider<DigestiveJournalController, List<DigestiveEntry>>(
      DigestiveJournalController.new,
    );
