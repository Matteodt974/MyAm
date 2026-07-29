package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.ProfilePreferencesRequest;
import com.uqam.inm5151.scan.dto.ProfilePreferencesResponse;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * UC-13B : source de verite serveur pour les allergies et regimes d'un profil, ce qui permet a un
 * meme compte de retrouver son profil sur un autre appareil.
 *
 * <p>Un profil designe soit le compte authentifie lui-meme, soit un de ses sous-profils enfants
 * (UC-27) : le client manipule les deux de la meme facon, via un identifiant de profil.
 */
@Service
public class ProfilePreferencesService {

  /** Garde-fou sur les entrees libres : au-dela, c'est une saisie erronee, pas un allergene. */
  private static final int MAX_ALLERGEN_LENGTH = 80;

  private final UserRepository users;
  private final CurrentUserService currentUser;

  public ProfilePreferencesService(UserRepository users, CurrentUserService currentUser) {
    this.users = users;
    this.currentUser = currentUser;
  }

  @Transactional(readOnly = true)
  public ProfilePreferencesResponse get(Long profileId) {
    return ProfilePreferencesResponse.from(requireAccessibleProfile(profileId));
  }

  @Transactional
  public ProfilePreferencesResponse replace(Long profileId, ProfilePreferencesRequest request) {
    User profile = requireAccessibleProfile(profileId);
    profile.replacePreferences(
        normalizeAllergies(request.allergies()), normalizeDiets(request.diets()));
    return ProfilePreferencesResponse.from(users.save(profile));
  }

  /**
   * Meme normalisation que le client : minuscules et espaces rognes, pour qu'un allergene saisi sur
   * un appareil corresponde a celui saisi sur un autre.
   */
  private static Set<String> normalizeAllergies(Set<String> raw) {
    Set<String> normalized = new LinkedHashSet<>();
    for (String allergy : raw) {
      if (allergy == null || allergy.isBlank()) {
        continue;
      }
      String value = allergy.trim().toLowerCase();
      if (value.length() > MAX_ALLERGEN_LENGTH) {
        throw new ResponseStatusException(
            HttpStatus.BAD_REQUEST, "Allergène trop long : " + value.substring(0, 20) + "...");
      }
      normalized.add(value);
    }
    return normalized;
  }

  /** Les regimes sont un vocabulaire ferme : une valeur inconnue est rejetee plutot qu'ignoree. */
  private static Set<String> normalizeDiets(Set<String> raw) {
    Set<String> normalized = new LinkedHashSet<>();
    for (String diet : raw) {
      if (diet == null || diet.isBlank()) {
        continue;
      }
      String value = diet.trim().toUpperCase();
      Diet.tryParse(value)
          .orElseThrow(
              () ->
                  new ResponseStatusException(
                      HttpStatus.BAD_REQUEST, "Régime alimentaire inconnu : " + diet));
      normalized.add(value);
    }
    return normalized;
  }

  /** Le compte authentifie, ou un enfant dont il est le gardien. */
  private User requireAccessibleProfile(Long profileId) {
    User authenticated = currentUser.getAuthenticatedUser();
    if (authenticated.getId().equals(profileId)) {
      return authenticated;
    }

    User profile =
        users
            .findById(profileId)
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profil introuvable"));

    if (!Objects.equals(profile.getGuardianUserId(), authenticated.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Profil non accessible");
    }
    return profile;
  }
}
