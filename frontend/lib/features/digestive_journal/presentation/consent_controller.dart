import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/consent_local_store.dart';

enum ConsentDecision { undecided, granted, refused }

class ConsentController extends AsyncNotifier<ConsentDecision> {
  @override
  Future<ConsentDecision> build() async {
    final persisted = await ref.read(consentLocalStoreProvider).load();
    return persisted ? ConsentDecision.granted : ConsentDecision.undecided;
  }

  Future<void> giveConsent({bool rememberChoice = false}) async {
    if (rememberChoice) {
      try {
        await ref.read(consentLocalStoreProvider).save(true);
      } catch (_) {
        // Ignore storage failures — the user has still given consent in-memory.
      }
    }
    state = const AsyncData(ConsentDecision.granted);
  }

  void refuseConsent() {
    state = const AsyncData(ConsentDecision.refused);
  }

  Future<void> resetConsent() async {
    await ref.read(consentLocalStoreProvider).clear();
    state = const AsyncData(ConsentDecision.undecided);
  }
}

final consentControllerProvider =
    AsyncNotifierProvider<ConsentController, ConsentDecision>(
      ConsentController.new,
    );
