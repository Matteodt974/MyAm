package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record BarcodeResponse(
        String ean,
        String name,
        String brands,
        String nutriscore,
        @JsonProperty("nova_group") Integer novaGroup,
        @JsonProperty("additives_tags") List<String> additivesTags,
        @JsonProperty("allergens_tags") List<String> allergensTags,
        @JsonProperty("traces_tags") List<String> tracesTags,
        @JsonProperty("ingredients_analysis_tags") List<String> ingredientsAnalysisTags,
        @JsonProperty("label_tags") List<String> labelTags,
        @JsonProperty("diet_compatible") boolean dietCompatible,
        @JsonProperty("risk_level") String riskLevel,
        @JsonProperty("matched_allergens") List<String> matchedAllergens,
        @JsonProperty("undetermined_allergens") List<String> undeterminedAllergens) {
}
