package com.uqam.inm5151.scan.service;

import java.util.List;

public record GeminiDishAnalysis(
    String dishName,
    String enName,
    Double confidence,
    List<DishCandidate> candidates,
    List<ProbableIngredient> ingredients,
    List<String> ingredientsEn) {
  public GeminiDishAnalysis(
      String dishName,
      String enName,
      Double confidence,
      List<DishCandidate> candidates,
      List<ProbableIngredient> ingredients) {
    this(dishName, enName, confidence, candidates, ingredients, List.of());
  }

  public record DishCandidate(String name, Double confidence) {}

  public record ProbableIngredient(String name, Double confidence) {}
}
