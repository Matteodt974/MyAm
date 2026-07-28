package com.uqam.inm5151.scan.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;
import java.time.Instant;

/** UC-23 : creation d'une entree du journal digestif (echelle de Bristol). */
public record DigestiveEntryRequest(
    @NotNull(message = "Le type Bristol est requis")
        @Min(value = 1, message = "Le type Bristol doit être entre 1 et 7")
        @Max(value = 7, message = "Le type Bristol doit être entre 1 et 7")
        Integer bristolType,
    @NotNull(message = "La date de l'épisode est requise")
        @PastOrPresent(message = "La date ne peut pas être dans le futur")
        Instant occurredAt,
    @Size(max = 1000, message = "Les notes ne peuvent pas dépasser 1000 caractères")
        String notes) {}
