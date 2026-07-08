import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/language_local_store.dart';

class LanguageController extends AsyncNotifier<String> {
  @override
  Future<String> build() {
    return ref.read(languageLocalStoreProvider).load();
  }

  Future<void> setLanguage(String code) async {
    state = AsyncData(code);

    await ref.read(languageLocalStoreProvider).save(code);
  }
}

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, String>(LanguageController.new);
