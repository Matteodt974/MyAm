package com.uqam.inm5151.scan.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

/** Corps de la requete POST /v1/label/translate-and-structure. */
public record LabelTextRequest(@NotBlank String text, String language, List<String> allergies) {}
