package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * UC-20 : profil nutritionnel d'un produit, exprime pour 100 g / 100 ml (unite de reference d'Open
 * Food Facts). Toute valeur absente de la fiche OFF reste {@code null} : le frontend affiche alors
 * un tiret plutot qu'un zero trompeur.
 */
@JsonInclude(JsonInclude.Include.ALWAYS)
public record Nutriments(
    @JsonProperty("energy_kcal") Double energyKcal,
    Double fat,
    Double carbohydrates,
    Double proteins,
    Double salt,
    Double fiber) {

  /** Vrai si aucune valeur n'est disponible : evite d'afficher un tableau vide. */
  public boolean isEmpty() {
    return energyKcal == null
        && fat == null
        && carbohydrates == null
        && proteins == null
        && salt == null
        && fiber == null;
  }
}
