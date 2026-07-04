package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record LabelResponse(
        List<String> ingredients,
        @JsonProperty("risk_level") String riskLevel,
        @JsonProperty("matched_allergens") List<String> matchedAllergens,
        @JsonProperty("undetermined_allergens") List<String> undeterminedAllergens) {
}