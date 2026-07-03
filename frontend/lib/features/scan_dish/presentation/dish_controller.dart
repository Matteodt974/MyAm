import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../history/data/scan_history_entry.dart';
import '../../history/data/scan_history_repository.dart';
import '../../profile_allergies/presentation/language_controller.dart';
import '../data/dish_repository.dart';

import '../data/dish_result.dart';

class DishController extends Notifier<AsyncValue<DishResult?>> {
  @override
  AsyncValue<DishResult?> build() => const AsyncData<DishResult?>(null);

  Future<void> analyze(File image) async {
    state = const AsyncLoading<DishResult?>();

    state = await AsyncValue.guard<DishResult?>(() async {
      final language = await ref.read(languageControllerProvider.future);
      return ref.read(dishRepositoryProvider).analyze(image, language);
    });

    if (state.value != null) {
      unawaited(_persistDishHistory(state.value!, image));
    }
  }

  Future<void> _persistDishHistory(
    DishResult result,
    File originalImage,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'dish_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final persistentFile = await originalImage.copy(
        '${appDir.path}/$fileName',
      );
      await ref
          .read(scanHistoryRepositoryProvider)
          .save(
            ScanHistoryEntry.fromDishResult(
              result,
              thumbnailPath: persistentFile.path,
            ),
          );
    } catch (e) {
      debugPrint('Failed to persist dish history: $e');
    }
  }

  void reset() => state = const AsyncData<DishResult?>(null);
}

final dishControllerProvider =
    NotifierProvider<DishController, AsyncValue<DishResult?>>(
      DishController.new,
    );
