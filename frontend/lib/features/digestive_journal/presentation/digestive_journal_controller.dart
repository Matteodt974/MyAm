import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/digestive_entry.dart';
import '../data/digestive_journal_repository.dart';

/// Controleur du journal digestif (UC-23).
class DigestiveJournalController extends AsyncNotifier<List<DigestiveEntry>> {
  @override
  Future<List<DigestiveEntry>> build() => _load();

  Future<List<DigestiveEntry>> _load() =>
      ref.read(digestiveJournalRepositoryProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading<List<DigestiveEntry>>();
    state = await AsyncValue.guard<List<DigestiveEntry>>(_load);
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
    await ref
        .read(digestiveJournalRepositoryProvider)
        .create(bristolType: bristolType, occurredAt: occurredAt, notes: notes);
    await refresh();
  }
}

final digestiveJournalControllerProvider =
    AsyncNotifierProvider<DigestiveJournalController, List<DigestiveEntry>>(
      DigestiveJournalController.new,
    );
