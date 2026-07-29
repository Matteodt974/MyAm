package com.uqam.inm5151.scan.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

/**
 * UC-26 : requete d'analyse d'intolerance.
 *
 * <p>Le journal alimentaire des 72 dernieres heures vit cote mobile (historique de scans SQLite) :
 * le frontend l'envoie dans le corps de la requete plutot que de le synchroniser en base.
 */
public record IntoleranceAnalysisRequest(
    @NotNull(message = "Le profil est requis") Long profileId,
    @NotNull(message = "Le journal alimentaire est requis")
        @Size(max = 500, message = "Le journal alimentaire ne peut pas dépasser 500 aliments")
        List<@Valid FoodItem> foodItems) {

  /** Aliment consomme, issu d'un scan (code-barres, etiquette ou plat). */
  public record FoodItem(
      @NotBlank(message = "Le nom de l'aliment est requis") String name,
      @NotNull(message = "La date de consommation est requise") Instant consumedAt,
      List<String> allergens,
      String scanType) {

    public List<String> allergens() {
      return allergens == null ? List.of() : allergens;
    }
  }
}
