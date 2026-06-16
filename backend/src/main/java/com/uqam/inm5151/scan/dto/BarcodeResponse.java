package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Reponse de POST /v1/scan/barcode.
 *
 * <p>
 * Les cles JSON sont identiques au backend FastAPI : snake_case pour
 * {@code nova_group}, {@code additives_tags} et {@code allergens_tags}. Les
 * champs nuls sont
 * conserves dans la reponse (comme FastAPI) grace a
 * {@code JsonInclude.Include.ALWAYS}.
 * </p>
 */
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
                @JsonProperty("risk_level") String riskLevel,
                @JsonProperty("matched_allergens") List<String> matchedAllergens,
                @JsonProperty("undetermined_allergens") List<String> undeterminedAllergens) {
}
