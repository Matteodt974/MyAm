import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'allergy_local_store.dart';
import 'diet_local_store.dart';
import 'profile_preferences_repository.dart';

/// Au-dela, on n'attend plus le serveur : l'ecran de profil doit s'afficher
/// meme sur un reseau lent, quitte a montrer d'abord le cache local.
const _syncTimeout = Duration(seconds: 4);

/// Preferences du profil telles que le serveur les connait, ou `null` s'il est
/// injoignable : le stockage local sert alors de repli hors ligne (UC-13B).
///
/// Volontairement sans provider de cache : une valeur memorisee survivrait aux
/// ecritures locales et finirait par ecraser une modification plus recente lors
/// d'une reconstruction du controleur.
Future<ProfilePreferences?> fetchProfilePreferences(
  Ref ref,
  int profileId,
) async {
  try {
    return await ref
        .read(profilePreferencesRepositoryProvider)
        .fetch(profileId)
        .timeout(_syncTimeout);
  } on Object {
    return null;
  }
}

/// Renvoie au serveur l'etat complet du profil, l'endpoint remplacant les deux
/// listes d'un coup. L'appelant fournit celle qu'il vient de modifier ; l'autre
/// est relue du stockage local.
///
/// Appele apres chaque ecriture locale : le stockage local reste la reference
/// immediate, la synchronisation est au mieux et n'echoue jamais visiblement
/// hors ligne.
Future<void> pushProfilePreferences(
  Ref ref, {
  required int profileId,
  required bool isParent,
  List<String>? allergies,
  List<String>? diets,
}) async {
  try {
    final pushedAllergies =
        allergies ??
        await ref
            .read(allergyLocalStoreProvider)
            .load(profileId, isParent: isParent);
    final pushedDiets =
        diets ??
        await ref
            .read(dietLocalStoreProvider)
            .load(profileId, isParent: isParent);

    await ref
        .read(profilePreferencesRepositoryProvider)
        .replace(profileId, allergies: pushedAllergies, diets: pushedDiets);
  } on Object {
    // Hors ligne ou serveur indisponible : la prochaine ecriture repoussera.
  }
}
