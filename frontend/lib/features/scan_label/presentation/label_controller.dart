import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/data/scan_history_entry.dart';
import '../../history/presentation/history_persistence.dart';
import '../../profile_allergies/presentation/language_controller.dart';
import '../data/label_repository.dart';
import '../data/label_result.dart';

class LabelController extends Notifier<AsyncValue<LabelResult?>> {
  @override
  AsyncValue<LabelResult?> build() => const AsyncData<LabelResult?>(null);

  /// Lance l'analyse de l'etiquette a partir du texte extrait par OCR.
  Future<void> analyze(String text) async {
    state = const AsyncLoading<LabelResult?>();

    state = await AsyncValue.guard<LabelResult?>(() async {
      final language = await ref.read(languageControllerProvider.future);
      return ref.read(labelRepositoryProvider).analyze(text, language);
    });

    if (state.value != null) {
      ref.persistScanToHistory(
        () => ScanHistoryEntry.fromLabelResult(state.value!),
      );
    }
  }

  void reset() => state = const AsyncData<LabelResult?>(null);
}

final labelControllerProvider =
    NotifierProvider<LabelController, AsyncValue<LabelResult?>>(
      LabelController.new,
    );
