package com.uqam.inm5151.scan.service;

import java.util.List;

public record GeminiDishAnalysis(
    String dishName,
    Double confidence,
    List<DishCandidate> candidates,
    List<ProbableIngredient> ingredients) {
  public record DishCandidate(String name, Double confidence) {}

  public record ProbableIngredient(String name, Double confidence) {}
}
