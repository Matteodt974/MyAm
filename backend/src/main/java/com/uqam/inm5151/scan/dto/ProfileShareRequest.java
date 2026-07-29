package com.uqam.inm5151.scan.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * UC-28 : creation d'un partage de profil enfant par code QR.
 *
 * <p>Les allergies et regimes vivent sur l'appareil du parent : le client en transmet donc un
 * instantane au moment du partage. {@code validityDays} null signifie une validite illimitee
 * (option "illimité" du cahier des charges).
 */
public record ProfileShareRequest(
    @NotBlank @Size(max = 255) String displayName,
    @Size(max = 100) List<@Size(max = 100) String> allergies,
    @Size(max = 100) List<@Size(max = 100) String> diets,
    @Min(1) @Max(365) Integer validityDays) {

  public List<String> allergies() {
    return allergies == null ? List.of() : allergies;
  }

  public List<String> diets() {
    return diets == null ? List.of() : diets;
  }
}
