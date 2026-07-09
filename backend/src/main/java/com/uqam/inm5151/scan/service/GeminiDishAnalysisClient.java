package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import com.uqam.inm5151.scan.dto.DishResponse;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
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

  /**
   * Fusionne les ingredients observes visuellement avec ceux d'une fiche FoodData Central proche du
   * plat. La fiche FDC est toujours en anglais (format etiquette) : si la langue cible est
   * l'anglais, un simple merge de chaines suffit (aucun appel Gemini necessaire). Sinon, on demande
   * a Gemini de dedupliquer les synonymes et de traduire les ingredients de la fiche dans la langue
   * cible.
   */
  public List<DishResponse.ProbableIngredient> mergeIngredients(
      String dishName,
      List<DishResponse.ProbableIngredient> visualIngredients,
      List<DishResponse.FoodDataMatch> matches,
      String language) {
    String labelIngredients =
        matches.stream()
            .map(DishResponse.FoodDataMatch::ingredients)
            .filter(s -> s != null && !s.isBlank())
            .findFirst()
            .orElse(null);
    if (labelIngredients == null) {
      return visualIngredients;
    }

    String target = normalizeLanguage(language);
    if (target.equals("en")) {
      return cheapMerge(visualIngredients, labelIngredients);
    }

    try {
      requireApiKey();
      String prompt = mergeIngredientsPrompt(dishName, visualIngredients, labelIngredients, target);
      Map<?, ?> response = generateContent(textOnlyBody(prompt));
      return parseMergedIngredients(response, cheapMerge(visualIngredients, labelIngredients));
    } catch (RuntimeException e) {
      log.warn(
          "Gemini ingredient merge failed, falling back to untranslated merge: {}", e.getMessage());
      return cheapMerge(visualIngredients, labelIngredients);
    }
  }

  private static List<DishResponse.ProbableIngredient> cheapMerge(
      List<DishResponse.ProbableIngredient> visualIngredients, String labelIngredients) {
    Set<String> seen =
        visualIngredients.stream().map(i -> i.name().toLowerCase()).collect(Collectors.toSet());
    List<DishResponse.ProbableIngredient> result = new ArrayList<>(visualIngredients);
    Arrays.stream(labelIngredients.split(","))
        .map(String::trim)
        .filter(s -> !s.isBlank() && seen.add(s.toLowerCase()))
        .forEach(name -> result.add(new DishResponse.ProbableIngredient(name, null)));
    return result;
  }

  private static String mergeIngredientsPrompt(
      String dishName,
      List<DishResponse.ProbableIngredient> visualIngredients,
      String labelIngredients,
      String targetLanguage) {
    String visualList =
        visualIngredients.stream()
            .map(
                i ->
                    i.name()
                        + (i.confidence() == null ? "" : " (confidence " + i.confidence() + ")"))
            .reduce("", (left, right) -> left.isBlank() ? right : left + ", " + right);
    return """
        Plat identifie: "%s"
        Ingredients observes visuellement sur la photo: %s
        Liste d'ingredients d'une fiche produit similaire (USDA FoodData Central, en anglais,
        format etiquette d'emballage): "%s"

        Fusionne ces deux sources en une seule liste d'ingredients probables pour ce plat, dans
        la langue cible (code ISO 639-1: %s).
        Regles:
        - Deduplique les synonymes et variantes linguistiques d'un meme ingredient.
        - Traduis tous les noms d'ingredients dans la langue cible.
        - Conserve la valeur confidence fournie pour les ingredients observes visuellement.
        - Pour les ingredients qui ne proviennent que de la fiche produit (non observes
          visuellement), mets confidence a null.
        - Ignore les mentions non alimentaires (allergenes, "may contain", pourcentages, codes E)
          sauf si elles nomment un ingredient reel.
        Reponds uniquement avec ce JSON strict, sans autre texte:
        {"ingredients": [{"name": string, "confidence": number|null}]}
        """
        .formatted(
            dishName,
            visualList.isBlank() ? "aucun" : visualList,
            labelIngredients,
            targetLanguage);
  }

  private static Map<String, Object> textOnlyBody(String prompt) {
    return Map.of(
        "contents",
        List.of(Map.of("role", "user", "parts", List.of(Map.of("text", prompt)))),
        "generationConfig",
        Map.of("temperature", 0, "response_mime_type", "application/json"));
  }

  private List<DishResponse.ProbableIngredient> parseMergedIngredients(
      Map<?, ?> response, List<DishResponse.ProbableIngredient> fallback) {
    String text = extractText(response);
    if (text == null || text.isBlank()) {
      return fallback;
    }
    try {
      JsonNode root = objectMapper.readTree(stripCodeFence(text));
      JsonNode node = root.get("ingredients");
      if (node == null || !node.isArray()) {
        return fallback;
      }
      List<DishResponse.ProbableIngredient> merged = new ArrayList<>();
      for (JsonNode item : node) {
        String name = textOrNull(item.get("name"));
        if (name != null) {
          merged.add(
              new DishResponse.ProbableIngredient(name, doubleOrNull(item.get("confidence"))));
        }
      }
      return merged.isEmpty() ? fallback : merged;
    } catch (Exception e) {
      log.warn(
          "Gemini merged-ingredients JSON invalid, keeping untranslated merge: {}", e.getMessage());
      return fallback;
    }
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
