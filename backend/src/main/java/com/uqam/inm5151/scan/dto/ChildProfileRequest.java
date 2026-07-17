package com.uqam.inm5151.scan.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChildProfileRequest(
    @NotBlank(message = "Le nom de l'enfant est obligatoire")
        @Size(max = 80, message = "Le nom ne peut pas dépasser 80 caractères")
        String displayName) {}
