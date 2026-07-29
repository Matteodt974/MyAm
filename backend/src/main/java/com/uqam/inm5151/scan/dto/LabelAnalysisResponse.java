package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record LabelAnalysisResponse(
    @JsonProperty("original_language") String originalLanguage,
    boolean translated,
    @JsonProperty("translated_text") String translatedText,
    List<LabelIngredient> ingredients,
    @JsonProperty("risk_level") String riskLevel,
    @JsonProperty("matched_allergens") List<String> matchedAllergens,
    @JsonProperty("diet_compatible") boolean dietCompatible,
    @JsonProperty("diet_status") String dietStatus,
    @JsonProperty("diet_warning_diet") String dietWarningDiet) {}
