package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class GeminiDishAnalysisClient extends AbstractGeminiClient {

  private static final Logger log = LoggerFactory.getLogger(GeminiDishAnalysisClient.class);

  private static final String PROMPT =
      """
      Analyse cette photo. Identifie l'element alimentaire principal si l'image montre un plat,
      une boisson, un aliment emballe, un complement alimentaire, des comprimes de cafeine,
      des ingredients, ou un produit destine a etre ingere.
      Reponds uniquement avec un objet JSON strict:
      {
        "dish_name": string|null,
        "en_name": string|null,
        "confidence": number,
        "candidates": [{"name": string, "confidence": number}],
        "ingredients": [{"name": string, "confidence": number}]
      }
      dish_name doit etre le nom le plus precis visible ou fortement probable: plat, boisson,
      produit, supplement, ou categorie alimentaire. La confiance doit etre entre 0 et 1.
      en_name doit etre le nom en anglais de ce meme aliment, tel qu'il apparaitrait dans une
      base de donnees alimentaire anglophone (ex: USDA FoodData Central). Utilise le nom de
      marque anglais si visible sur l'emballage.
      Liste seulement les ingredients ou composants visibles/probables.
      Ne fais aucune affirmation medicale, nutritionnelle ou allergene.
      Retourne dish_name null, confidence 0, et des listes vides seulement si l'image ne montre
      aucun aliment, boisson, supplement, ingredient, produit ingestible, emballage alimentaire,
      etiquette alimentaire, ou objet clairement lie a l'alimentation.
      """;

  private static final String FALLBACK_PROMPT =
      """
      Deuxieme verification: l'analyse precedente n'a rien identifie.
      Si l'image montre un produit consommable ou lie a l'alimentation, meme si ce n'est pas
      un plat cuisine, identifie-le. Les comprimes de cafeine, supplements, boissons,
      emballages, ingredients et aliments simples doivent etre identifies quand ils sont visibles.
      Reponds uniquement avec ce JSON strict:
      {
        "dish_name": string|null,
        "en_name": string|null,
        "confidence": number,
        "candidates": [{"name": string, "confidence": number}],
        "ingredients": [{"name": string, "confidence": number}]
      }
      en_name doit etre le nom en anglais tel qu'il apparaitrait dans une base de donnees
      alimentaire anglophone (ex: USDA FoodData Central).
      Ne retourne null que si l'image ne contient vraiment aucun indice de nourriture,
      boisson, supplement, ingredient, produit ingestible ou emballage alimentaire.
      Ne fais aucune affirmation medicale, nutritionnelle ou allergene.
      """;

  public GeminiDishAnalysisClient(AppProperties props, ObjectMapper objectMapper) {
    super(props, objectMapper);
  }

  public GeminiDishAnalysis analyze(byte[] imageBytes, String contentType, String language) {
    requireApiKey();

    String target = normalizeLanguage(language);
    GeminiDishAnalysis analysis =
        requestAnalysis(imageBytes, contentType, withLanguage(PROMPT, target));
    if (isUnrecognized(analysis)) {
      log.info(
          "Gemini returned no dish on first pass; retrying with broad consumable-product prompt");
      return requestAnalysis(imageBytes, contentType, withLanguage(FALLBACK_PROMPT, target));
    }
    return analysis;
  }

  private static String withLanguage(String prompt, String targetLanguage) {
    String target = normalizeLanguage(targetLanguage);
    String displayName = languageName(target);
    return prompt
        + "\nIMPORTANT - target output language: "
        + displayName
        + " (ISO 639-1 code: "
        + target
        + "). All user-facing JSON fields must be written in that target language: dish_name,"
        + " candidates[].name, and ingredients[].name. Do not answer those fields in French unless"
        + " the target language is fr. en_name must always remain English because it is used only as"
        + " a search key for USDA FoodData Central.";
  }

  private static String languageName(String language) {
    return switch (language) {
      case "en" -> "English";
      case "es" -> "Spanish";
      case "de" -> "German";
      case "it" -> "Italian";
      case "pt" -> "Portuguese";
      case "nl" -> "Dutch";
      case "pl" -> "Polish";
      case "ru" -> "Russian";
      case "zh" -> "Chinese";
      case "ja" -> "Japanese";
      case "ko" -> "Korean";
      case "ar" -> "Arabic";
      case "fr" -> "French";
      default -> language;
    };
  }

  private GeminiDishAnalysis requestAnalysis(byte[] imageBytes, String contentType, String prompt) {
    Map<String, Object> body =
        Map.of(
            "contents",
            List.of(
                Map.of(
                    "role",
                    "user",
                    "parts",
                    List.of(
                        Map.of(
                            "inline_data",
                            Map.of(
                                "mime_type",
                                contentType,
                                "data",
                                Base64.getEncoder().encodeToString(imageBytes))),
                        Map.of("text", prompt)))),
            "generationConfig",
            Map.of("temperature", 0, "response_mime_type", "application/json"));

    Map<?, ?> response = generateContent(body);
    return parseResponse(response);
  }

  private static boolean isUnrecognized(GeminiDishAnalysis analysis) {
    return analysis.dishName() == null
        || analysis.dishName().isBlank()
        || analysis.confidence() == null
        || analysis.confidence() <= 0;
  }

  private GeminiDishAnalysis parseResponse(Map<?, ?> response) {
    String text = extractText(response);
    if (text == null || text.isBlank()) {
      throw new GeminiDishAnalysisException("Gemini n'a pas retourne de JSON");
    }
    log.info("Gemini dish JSON: {}", compactForLog(text));

    try {
      JsonNode root = objectMapper.readTree(stripCodeFence(text));
      return new GeminiDishAnalysis(
          textOrNull(field(root, "dish_name", "dishName")),
          textOrNull(field(root, "en_name", "enName")),
          doubleOrNull(field(root, "confidence")),
          candidates(root.get("candidates")),
          ingredients(root.get("ingredients")));
    } catch (Exception e) {
      throw new GeminiDishAnalysisException("JSON Gemini invalide", e);
    }
  }

  private static List<GeminiDishAnalysis.DishCandidate> candidates(JsonNode node) {
    if (node == null || !node.isArray()) {
      return List.of();
    }
    List<GeminiDishAnalysis.DishCandidate> values = new ArrayList<>();
    for (JsonNode item : node) {
      String name = textOrNull(item.get("name"));
      if (name != null) {
        values.add(
            new GeminiDishAnalysis.DishCandidate(name, doubleOrNull(item.get("confidence"))));
      }
    }
    return values;
  }

  private static List<GeminiDishAnalysis.ProbableIngredient> ingredients(JsonNode node) {
    if (node == null || !node.isArray()) {
      return List.of();
    }
    List<GeminiDishAnalysis.ProbableIngredient> values = new ArrayList<>();
    for (JsonNode item : node) {
      String name = textOrNull(item.get("name"));
      if (name != null) {
        values.add(
            new GeminiDishAnalysis.ProbableIngredient(name, doubleOrNull(item.get("confidence"))));
      }
    }
    return values;
  }

  private static Double doubleOrNull(JsonNode node) {
    if (node == null) {
      return null;
    }
    if (node.isNumber()) {
      return Math.max(0, Math.min(1, node.asDouble()));
    }
    if (node.isTextual()) {
      try {
        return Math.max(0, Math.min(1, Double.parseDouble(node.asText())));
      } catch (NumberFormatException ignored) {
        return null;
      }
    }
    return null;
  }
}
