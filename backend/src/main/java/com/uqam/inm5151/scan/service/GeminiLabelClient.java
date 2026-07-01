package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import java.time.Duration;
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

/**
 * Client Gemini dedie a UC-06 : detection de la langue d'une liste d'ingredients et traduction vers
 * l'anglais si necessaire.
 */
@Service
public class GeminiLabelClient {

  private static final Logger log = LoggerFactory.getLogger(GeminiLabelClient.class);

  private static final String PROMPT_TEMPLATE =
      """
            Detect the language of the following ingredient list and translate it to English if it is not already English.
            Return ONLY a JSON object with this exact shape:
            {"language":"<iso-639-1 code>","translated_text":"<english text>","is_english":true|false}
            Text: \"\"\"%s\"\"\"
            """;

  private final RestClient client;
  private final ObjectMapper objectMapper;
  private final String apiKey;
  private final String model;

  public GeminiLabelClient(AppProperties props, ObjectMapper objectMapper) {
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

  public TranslationResult detectAndTranslate(String text) {
    if (apiKey == null || apiKey.isBlank()) {
      throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "GEMINI_API_KEY manquante");
    }

    Map<String, Object> body =
        Map.of(
            "contents",
                List.of(
                    Map.of(
                        "role",
                        "user",
                        "parts",
                        List.of(Map.of("text", PROMPT_TEMPLATE.formatted(text))))),
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

    return parseResponse(text, response);
  }

  private TranslationResult parseResponse(String originalText, Map<?, ?> response) {
    String text = extractText(response);
    if (text == null || text.isBlank()) {
      throw new GeminiDishAnalysisException("Gemini n'a pas retourne de JSON");
    }
    log.info("Gemini label JSON: {}", compactForLog(text));

    try {
      JsonNode root = objectMapper.readTree(stripCodeFence(text));
      String language = textOrNull(field(root, "language"));
      String translatedText = textOrNull(field(root, "translated_text"));
      boolean isEnglish = booleanOrFalse(field(root, "is_english"));

      if (language == null || language.isBlank()) {
        throw new UnsupportedLanguageException("Langue non identifiable");
      }

      boolean english =
          isEnglish || language.equalsIgnoreCase("en") || language.equalsIgnoreCase("english");

      if (english) {
        return new TranslationResult(language.toLowerCase(), originalText, true);
      }

      if (translatedText == null || translatedText.isBlank()) {
        throw new GeminiDishAnalysisException("Gemini n'a pas fourni de traduction");
      }
      return new TranslationResult(language.toLowerCase(), translatedText, false);
    } catch (UnsupportedLanguageException e) {
      throw e;
    } catch (Exception e) {
      throw new GeminiDishAnalysisException("JSON Gemini invalide", e);
    }
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

  private static JsonNode field(JsonNode root, String name) {
    if (root == null) {
      return null;
    }
    JsonNode value = root.get(name);
    return value != null && !value.isMissingNode() && !value.isNull() ? value : null;
  }

  private static String textOrNull(JsonNode node) {
    if (node == null || node.isNull()) {
      return null;
    }
    String value = node.asText(null);
    return value == null || value.isBlank() ? null : value.trim();
  }

  private static boolean booleanOrFalse(JsonNode node) {
    if (node == null) {
      return false;
    }
    if (node.isBoolean()) {
      return node.asBoolean();
    }
    if (node.isTextual()) {
      return Boolean.parseBoolean(node.asText());
    }
    return false;
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

  public record TranslationResult(String language, String translatedText, boolean english) {}
}
