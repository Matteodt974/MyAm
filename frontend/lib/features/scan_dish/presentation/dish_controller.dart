import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../child_profiles/presentation/parent_scan_alert_controller.dart';
import '../../history/data/scan_history_entry.dart';
import '../../history/presentation/history_persistence.dart';
import '../../profile_allergies/presentation/allergy_controller.dart';
import '../../profile_allergies/presentation/language_controller.dart';
import '../data/dish_repository.dart';
import '../data/dish_result.dart';

class DishController extends Notifier<AsyncValue<DishResult?>> {
  @override
  AsyncValue<DishResult?> build() => const AsyncData<DishResult?>(null);

  Future<void> analyze(File image, List<String> diets) async {
    state = const AsyncLoading<DishResult?>();

    state = await AsyncValue.guard<DishResult?>(() async {
      final language = await ref.read(languageControllerProvider.future);
      return ref.read(dishRepositoryProvider).analyze(image, language, diets);
    });

    if (state.value != null) {
      final result = state.value!;
      await ref.read(parentScanAlertControllerProvider.notifier).recordIfNeeded(
        incompatible: result.dietStatus == 'incompatible' ||
            flaggedDishIngredients(result.ingredients, await ref.read(allergyControllerProvider.future)).isNotEmpty,
        childDisplayName: 'Profil enfant',
        message:
            'Le plat analysé contient un allergène ou un régime incompatible pour le profil enfant actif.',
      );
      ref.persistScanToHistory(() => _buildHistoryEntry(result, image));
    }
  }

  Future<ScanHistoryEntry> _buildHistoryEntry(
    DishResult result,
    File originalImage,
  ) async {
    String? thumbnailPath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'dish_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final persistentFile = await originalImage.copy(
        '${appDir.path}/$fileName',
      );
      thumbnailPath = persistentFile.path;
    } catch (e) {
      debugPrint('Failed to persist dish thumbnail: $e');
    }
    final allergies = await ref.read(allergyControllerProvider.future);
    return ScanHistoryEntry.fromDishResult(
      result,
      allergies: allergies,
      thumbnailPath: thumbnailPath,
    );
  }

  void reset() => state = const AsyncData<DishResult?>(null);
}

final dishControllerProvider =
    NotifierProvider<DishController, AsyncValue<DishResult?>>(
      DishController.new,
    );
