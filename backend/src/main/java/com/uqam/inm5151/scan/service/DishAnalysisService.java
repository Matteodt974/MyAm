package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.dto.DishResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DishAnalysisService {

  private static final Logger log = LoggerFactory.getLogger(DishAnalysisService.class);

  private static final double LOW_CONFIDENCE_THRESHOLD = 0.70;
  private static final int FOOD_MATCH_LIMIT = 5;

  private final GeminiDishAnalysisClient gemini;
  private final FoodDataCentralClient foodDataCentral;

  public DishAnalysisService(
      GeminiDishAnalysisClient gemini, FoodDataCentralClient foodDataCentral) {
    this.gemini = gemini;
    this.foodDataCentral = foodDataCentral;
  }

  public DishResponse analyze(MultipartFile image, String language) {
    byte[] bytes;
    try {
      bytes = image.getBytes();
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Image illisible");
    }
    if (bytes.length == 0) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Image vide");
    }

    GeminiDishAnalysis analysis;
    try {
      analysis = gemini.analyze(bytes, image.getContentType(), language);
    } catch (GeminiDishAnalysisException e) {
      log.warn("Gemini dish JSON could not be parsed: {}", e.getMessage());
      return unrecognized(image, "Gemini n'a pas pu identifier le plat avec certitude.");
    }

    String dishName = analysis.dishName();
    Double confidence = analysis.confidence() == null ? 0 : analysis.confidence();
    List<DishResponse.DishCandidate> candidates =
        analysis.candidates().stream()
            .map(c -> new DishResponse.DishCandidate(c.name(), c.confidence()))
            .toList();
    List<DishResponse.ProbableIngredient> ingredients =
        analysis.ingredients().stream()
            .map(i -> new DishResponse.ProbableIngredient(i.name(), i.confidence()))
            .toList();

    if (dishName == null || dishName.isBlank() || confidence <= 0) {
      log.info(
          "Gemini did not identify a dish. dishName={}, confidence={}, candidates={}, ingredients={}",
          dishName,
          confidence,
          candidates.size(),
          ingredients.size());
      return new DishResponse(
          image.getOriginalFilename(),
          image.getContentType(),
          image.getSize(),
          "unrecognized",
          "Aucun plat n'a pu etre identifie.",
          null,
          confidence,
          candidates,
          ingredients,
          List.of());
    }

    String fdcQueryName =
        analysis.enName() != null && !analysis.enName().isBlank() ? analysis.enName() : dishName;
    List<DishResponse.FoodDataMatch> matches;
    try {
      matches = foodDataCentral.search(foodQuery(fdcQueryName, ingredients), FOOD_MATCH_LIMIT);
    } catch (RuntimeException e) {
      matches = List.of();
    }
    ingredients = mergeWithFdcIngredients(ingredients, matches);
    String status = confidence < LOW_CONFIDENCE_THRESHOLD ? "low_confidence" : "identified";
    String message =
        confidence < LOW_CONFIDENCE_THRESHOLD
            ? "Identification incertaine. Verifiez le resultat avant de l'utiliser."
            : "Plat identifie a partir de la photo.";

    return new DishResponse(
        image.getOriginalFilename(),
        image.getContentType(),
        image.getSize(),
        status,
        message,
        dishName,
        confidence,
        candidates,
        ingredients,
        matches);
  }

  private static DishResponse unrecognized(MultipartFile image, String message) {
    return new DishResponse(
        image.getOriginalFilename(),
        image.getContentType(),
        image.getSize(),
        "unrecognized",
        message,
        null,
        0.0,
        List.of(),
        List.of(),
        List.of());
  }

  private static List<DishResponse.ProbableIngredient> mergeWithFdcIngredients(
      List<DishResponse.ProbableIngredient> geminiIngredients,
      List<DishResponse.FoodDataMatch> matches) {
    String fdcStr =
        matches.stream()
            .map(DishResponse.FoodDataMatch::ingredients)
            .filter(s -> s != null && !s.isBlank())
            .findFirst()
            .orElse(null);
    if (fdcStr == null) return geminiIngredients;
    Set<String> seen =
        geminiIngredients.stream().map(i -> i.name().toLowerCase()).collect(Collectors.toSet());
    List<DishResponse.ProbableIngredient> result = new ArrayList<>(geminiIngredients);
    Arrays.stream(fdcStr.split(","))
        .map(String::trim)
        .filter(s -> !s.isBlank() && seen.add(s.toLowerCase()))
        .forEach(name -> result.add(new DishResponse.ProbableIngredient(name, null)));
    return result;
  }

  private static String foodQuery(
      String dishName, List<DishResponse.ProbableIngredient> ingredients) {
    String ingredientNames =
        ingredients.stream()
            .limit(3)
            .map(DishResponse.ProbableIngredient::name)
            .filter(name -> name != null && !name.isBlank())
            .reduce("", (left, right) -> left.isBlank() ? right : left + " " + right);
    return ingredientNames.isBlank() ? dishName : dishName + " " + ingredientNames;
  }
}
