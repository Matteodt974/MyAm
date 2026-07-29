package com.uqam.inm5151.scan.api;

import com.uqam.inm5151.scan.dto.ProfilePreferencesRequest;
import com.uqam.inm5151.scan.dto.ProfilePreferencesResponse;
import com.uqam.inm5151.scan.service.ProfilePreferencesService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * UC-13B : synchronisation du profil (allergies et regimes) entre les appareils d'un meme compte.
 * {@code profileId} designe le compte authentifie ou un de ses sous-profils enfants.
 */
@RestController
@RequestMapping("/v1/profiles/{profileId}/preferences")
public class ProfilePreferencesController {
  private final ProfilePreferencesService preferences;

  public ProfilePreferencesController(ProfilePreferencesService preferences) {
    this.preferences = preferences;
  }

  @GetMapping
  public ProfilePreferencesResponse get(@PathVariable Long profileId) {
    return preferences.get(profileId);
  }

  @PutMapping
  public ProfilePreferencesResponse replace(
      @PathVariable Long profileId, @Valid @RequestBody ProfilePreferencesRequest request) {

    return preferences.replace(profileId, request);
  }
}
