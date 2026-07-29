package com.uqam.inm5151.scan.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;

/**
 * Corps de PUT /v1/profiles/{profileId}/preferences. Remplace integralement les allergies et
 * regimes du profil : le client envoie l'etat complet, pas un delta.
 */
public record ProfilePreferencesRequest(
    @NotNull(message = "La liste d'allergies est obligatoire")
        @Size(max = 100, message = "Un profil ne peut pas dépasser 100 allergies")
        Set<String> allergies,
    @NotNull(message = "La liste de régimes est obligatoire")
        @Size(max = 20, message = "Un profil ne peut pas dépasser 20 régimes")
        Set<String> diets) {}
