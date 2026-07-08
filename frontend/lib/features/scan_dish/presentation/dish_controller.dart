import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  void reset() => state = const AsyncData<DishResult?>(null);
}

final dishControllerProvider =
    NotifierProvider<DishController, AsyncValue<DishResult?>>(
      DishController.new,
    );
