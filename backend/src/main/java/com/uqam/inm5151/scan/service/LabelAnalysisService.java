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

  public LabelAnalysisService(GeminiLabelClient gemini, IngredientParser parser) {
    this.gemini = gemini;
    this.parser = parser;
  }

  public LabelAnalysisResponse analyze(String text, String language) {
    if (text == null || text.isBlank()) {
      throw new IllegalArgumentException("Le texte est requis");
    }

    GeminiLabelClient.TranslationResult result = gemini.detectAndTranslate(text, language);
    List<LabelIngredient> ingredients =
        !result.ingredients().isEmpty()
            ? result.ingredients().stream().map(name -> new LabelIngredient(name, null)).toList()
            : parser.parse(result.translatedText());

    return new LabelAnalysisResponse(
        result.language(), !result.matchesTarget(), result.translatedText(), ingredients);
  }
}
