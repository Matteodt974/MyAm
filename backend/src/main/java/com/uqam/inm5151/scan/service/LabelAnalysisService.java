package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.dto.LabelAnalysisResponse;
import com.uqam.inm5151.scan.dto.LabelIngredient;
import java.util.List;
import org.springframework.stereotype.Service;

/** Service metier UC-06 : traduction et structuration d'une liste d'ingredients. */
@Service
public class LabelAnalysisService {

  private final GeminiLabelClient gemini;
  private final IngredientParser parser;
  private final AllergenCrossMatchService allergenCrossMatch;
  private final DietMatchService dietMatch;

  public LabelAnalysisService(
      GeminiLabelClient gemini,
      IngredientParser parser,
      AllergenCrossMatchService allergenCrossMatch,
      DietMatchService dietMatch) {
    this.gemini = gemini;
    this.parser = parser;
    this.allergenCrossMatch = allergenCrossMatch;
    this.dietMatch = dietMatch;
  }

  public LabelAnalysisResponse analyze(
      String text, String language, List<String> allergies, List<Diet> userDiets) {
    if (text == null || text.isBlank()) {
      throw new IllegalArgumentException("Le texte est requis");
    }

    GeminiLabelClient.TranslationResult result = gemini.detectAndTranslate(text, language);
    List<LabelIngredient> ingredients =
        !result.ingredients().isEmpty()
            ? result.ingredients().stream().map(name -> new LabelIngredient(name, null)).toList()
            : parser.parse(result.translatedText());

    List<String> ingredientNames = ingredients.stream().map(LabelIngredient::name).toList();
    List<String> dietIngredients =
        result.ingredientsEn().isEmpty() ? ingredientNames : result.ingredientsEn();
    List<String> safeAllergies = allergies == null ? List.of() : allergies;
    List<String> matched =
        allergenCrossMatch.findMatchesInIngredients(ingredientNames, safeAllergies);
    String riskLevel = matched.isEmpty() ? "SAFE" : "DANGER";

    // UC-14 sur le flux etiquette : une etiquette n'expose pas de tags Open Food Facts,
    // la compatibilite est donc deduite uniquement des ingredients extraits.
    boolean hasUserDiets = userDiets != null && !userDiets.isEmpty();
    boolean dietCompatible =
        hasUserDiets && dietMatch.isUserDietsCompatible(userDiets, List.of(), dietIngredients);
    Diet warningDiet =
        !hasUserDiets || dietCompatible
            ? null
            : dietMatch.firstIncompatibleDiet(userDiets, List.of(), dietIngredients);
    String dietStatus = !hasUserDiets ? "unknown" : dietCompatible ? "compatible" : "incompatible";

    return new LabelAnalysisResponse(
        result.language(),
        !result.matchesTarget(),
        result.translatedText(),
        ingredients,
        riskLevel,
        matched,
        dietCompatible,
        dietStatus,
        warningDiet == null ? null : warningDiet.name());
  }
}
