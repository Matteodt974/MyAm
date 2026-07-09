package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record DishResponse(
    String filename,
    @JsonProperty("content_type") String contentType,
    @JsonProperty("size_bytes") long sizeBytes,
    String status,
    String message,
    @JsonProperty("dish_name") String dishName,
    Double confidence,
    List<DishCandidate> candidates,
    List<ProbableIngredient> ingredients,
    @JsonProperty("food_data_matches") List<FoodDataMatch> foodDataMatches,
    @JsonProperty("diet_compatible") boolean dietCompatible,
    @JsonProperty("diet_status") String dietStatus,
    @JsonProperty("diet_warning_diet") String dietWarningDiet) {
  public record DishCandidate(String name, Double confidence) {}

  public record ProbableIngredient(String name, Double confidence) {}

  public record FoodDataMatch(
      @JsonProperty("fdc_id") Integer fdcId,
      String description,
      @JsonProperty("data_type") String dataType,
      @JsonProperty("brand_owner") String brandOwner,
      String ingredients) {}
}
