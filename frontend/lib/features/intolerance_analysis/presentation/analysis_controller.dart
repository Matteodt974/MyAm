import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child_profiles/presentation/child_profile_controller.dart';
import '../../history/data/scan_history_entry.dart';
import '../../history/data/scan_history_repository.dart';
import '../data/intolerance_analysis_repository.dart';
import '../data/intolerance_report.dart';

/// Fenetre du journal alimentaire imposee par le UC-26.
const Duration foodJournalWindow = Duration(hours: 72);

/// Controleur de l'analyse d'intolerance (UC-26).
///
/// L'etat vaut `null` tant que l'utilisateur n'a pas lance l'analyse.
class AnalysisController extends AsyncNotifier<IntoleranceReport?> {
  @override
  Future<IntoleranceReport?> build() async {
    ref.watch(guardianIdProvider);
    return null;
  }

  /// Assemble le journal alimentaire des 72 dernieres heures depuis
  /// l'historique de scans local, puis demande l'analyse au backend.
  Future<void> runAnalysis() async {
    state = const AsyncLoading<IntoleranceReport?>();

    state = await AsyncValue.guard<IntoleranceReport?>(() async {
      final foodItems = await _recentFoodItems();
      final profileId = ref.read(guardianIdProvider);
      if (profileId == null) return null;
      return ref
          .read(intoleranceAnalysisRepositoryProvider)
          .analyze(profileId, foodItems);
    });
  }

  Future<List<FoodItemPayload>> _recentFoodItems() async {
    final profileId = ref.read(guardianIdProvider);
    if (profileId == null) return const <FoodItemPayload>[];

    final since = DateTime.now().subtract(foodJournalWindow);
    final entries = await ref
        .read(scanHistoryRepositoryProvider)
        .load(profileId, filter: HistoryFilter(from: since));

    return entries.map(_toFoodItem).toList();
  }

  static FoodItemPayload _toFoodItem(ScanHistoryEntry entry) {
    return FoodItemPayload(
      name: entry.title,
      consumedAt: entry.scannedAt,
      allergens: entry.matchedAllergens,
      scanType: entry.type.name,
    );
  }

  /// Efface le rapport affiche (retour a l'ecran d'accueil de l'analyse).
  void reset() => state = const AsyncData<IntoleranceReport?>(null);
}

final analysisControllerProvider =
    AsyncNotifierProvider<AnalysisController, IntoleranceReport?>(
      AnalysisController.new,
    );
