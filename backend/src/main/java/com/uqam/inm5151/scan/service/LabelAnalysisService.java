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

  public LabelAnalysisService(
      GeminiLabelClient gemini,
      IngredientParser parser,
      AllergenCrossMatchService allergenCrossMatch) {
    this.gemini = gemini;
    this.parser = parser;
    this.allergenCrossMatch = allergenCrossMatch;
  }

  public LabelAnalysisResponse analyze(String text, String language, List<String> allergies) {
    if (text == null || text.isBlank()) {
      throw new IllegalArgumentException("Le texte est requis");
    }

    GeminiLabelClient.TranslationResult result = gemini.detectAndTranslate(text, language);
    List<LabelIngredient> ingredients =
        !result.ingredients().isEmpty()
            ? result.ingredients().stream().map(name -> new LabelIngredient(name, null)).toList()
            : parser.parse(result.translatedText());

    List<String> ingredientNames = ingredients.stream().map(LabelIngredient::name).toList();
    List<String> safeAllergies = allergies == null ? List.of() : allergies;
    List<String> matched =
        allergenCrossMatch.findMatchesInIngredients(ingredientNames, safeAllergies);
    String riskLevel = matched.isEmpty() ? "SAFE" : "DANGER";

    return new LabelAnalysisResponse(
        result.language(),
        !result.matchesTarget(),
        result.translatedText(),
        ingredients,
        riskLevel,
        matched);
  }
}
