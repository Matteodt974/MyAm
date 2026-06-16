package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GeminiDishAnalysisClient {

  private static final Logger log = LoggerFactory.getLogger(GeminiDishAnalysisClient.class);

  private static final String PROMPT =
      """
            Analyse cette photo. Identifie l'element alimentaire principal si l'image montre un plat,
            une boisson, un aliment emballe, un complement alimentaire, des comprimes de cafeine,
            des ingredients, ou un produit destine a etre ingere.
            Reponds uniquement avec un objet JSON strict:
            {
              "dish_name": string|null,
              "confidence": number,
              "candidates": [{"name": string, "confidence": number}],
              "ingredients": [{"name": string, "confidence": number}]
            }
            dish_name doit etre le nom le plus precis visible ou fortement probable: plat, boisson,
            produit, supplement, ou categorie alimentaire. La confiance doit etre entre 0 et 1.
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
              "confidence": number,
              "candidates": [{"name": string, "confidence": number}],
              "ingredients": [{"name": string, "confidence": number}]
            }
            Ne retourne null que si l'image ne contient vraiment aucun indice de nourriture,
            boisson, supplement, ingredient, produit ingestible ou emballage alimentaire.
            Ne fais aucune affirmation medicale, nutritionnelle ou allergene.
            """;

  private final RestClient client;
  private final ObjectMapper objectMapper;
  private final String apiKey;
  private final String model;

  public GeminiDishAnalysisClient(AppProperties props, ObjectMapper objectMapper) {
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(Duration.ofSeconds(10));
    factory.setReadTimeout(Duration.ofSeconds(30));
    this.client =
        RestClient.builder()
            .baseUrl("https://generativelanguage.googleapis.com")
            .requestFactory(factory)
            .build();
    this.objectMapper = objectMapper;
    this.apiKey = props.geminiApiKey();
    this.model = props.geminiModel();
  }

  @SuppressWarnings("rawtypes")
  public GeminiDishAnalysis analyze(byte[] imageBytes, String contentType) {
    if (apiKey == null || apiKey.isBlank()) {
      throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "GEMINI_API_KEY manquante");
    }

    GeminiDishAnalysis analysis = requestAnalysis(imageBytes, contentType, PROMPT);
    if (isUnrecognized(analysis)) {
      log.info(
          "Gemini returned no dish on first pass; retrying with broad consumable-product prompt");
      return requestAnalysis(imageBytes, contentType, FALLBACK_PROMPT);
    }
    return analysis;
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
            "generationConfig", Map.of("temperature", 0, "response_mime_type", "application/json"));

    Map response;
    try {
      response =
          client
              .post()
              .uri(
                  uri ->
                      uri.path("/v1beta/models/{model}:generateContent")
                          .queryParam("key", apiKey)
                          .build(model))
              .body(body)
              .retrieve()
              .body(Map.class);
    } catch (ResourceAccessException e) {
      throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini injoignable");
    } catch (RestClientResponseException e) {
      throw new ResponseStatusException(
          HttpStatus.BAD_GATEWAY,
          "Requete Gemini refusee (" + e.getStatusCode().value() + "): " + geminiErrorDetail(e));
    }

    return parseResponse(response);
  }

  private static boolean isUnrecognized(GeminiDishAnalysis analysis) {
    return analysis.dishName() == null
        || analysis.dishName().isBlank()
        || analysis.confidence() == null
        || analysis.confidence() <= 0;
  }

  private String geminiErrorDetail(RestClientResponseException e) {
    try {
      JsonNode root = objectMapper.readTree(e.getResponseBodyAsString());
      JsonNode message = root.at("/error/message");
      if (!message.isMissingNode() && !message.asText().isBlank()) {
        return message.asText();
      }
    } catch (Exception ignored) {
      // Fall back to the HTTP status text below.
    }
    String statusText = e.getStatusText();
    return statusText == null || statusText.isBlank() ? "aucun detail" : statusText;
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
          doubleOrNull(field(root, "confidence")),
          candidates(root.get("candidates")),
          ingredients(root.get("ingredients")));
    } catch (Exception e) {
      throw new GeminiDishAnalysisException("JSON Gemini invalide", e);
    }
  }

  @SuppressWarnings("unchecked")
  private static String extractText(Map<?, ?> response) {
    Object candidates = response.get("candidates");
    if (!(candidates instanceof List<?> candidateList) || candidateList.isEmpty()) {
      return null;
    }
    Object first = candidateList.getFirst();
    if (!(first instanceof Map<?, ?> candidate)) {
      return null;
    }
    Object content = candidate.get("content");
    if (!(content instanceof Map<?, ?> contentMap)) {
      return null;
    }
    Object parts = contentMap.get("parts");
    if (!(parts instanceof List<?> partList)) {
      return null;
    }
    StringBuilder sb = new StringBuilder();
    for (Object part : partList) {
      if (part instanceof Map<?, ?> partMap && partMap.get("text") instanceof String text) {
        sb.append(text);
      }
    }
    return sb.toString();
  }

  private static JsonNode field(JsonNode root, String... names) {
    for (String name : names) {
      JsonNode value = root.get(name);
      if (value != null && !value.isMissingNode() && !value.isNull()) {
        return value;
      }
    }
    return null;
  }

  private static String compactForLog(String text) {
    String compact = text.replaceAll("\\s+", " ").trim();
    return compact.length() <= 1200 ? compact : compact.substring(0, 1200) + "...";
  }

  private static String stripCodeFence(String text) {
    String trimmed = text.trim();
    if (!trimmed.startsWith("```")) {
      return trimmed;
    }
    int firstLine = trimmed.indexOf('\n');
    int lastFence = trimmed.lastIndexOf("```");
    if (firstLine >= 0 && lastFence > firstLine) {
      return trimmed.substring(firstLine + 1, lastFence).trim();
    }
    return trimmed;
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

  private static String textOrNull(JsonNode node) {
    if (node == null || node.isNull()) {
      return null;
    }
    String value = node.asText(null);
    return value == null || value.isBlank() ? null : value.trim();
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
