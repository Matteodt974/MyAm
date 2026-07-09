package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

/**
 * Plomberie commune aux clients Gemini (UC-06, UC-07, ...) : construction du {@link RestClient},
 * appel HTTP generateContent avec conversion des erreurs reseau/HTTP, et extraction du texte brut
 * renvoye par Gemini.
 */
abstract class AbstractGeminiClient {

  protected final RestClient client;
  protected final ObjectMapper objectMapper;
  protected final String apiKey;
  protected final String model;

  protected AbstractGeminiClient(AppProperties props, ObjectMapper objectMapper) {
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

  protected void requireApiKey() {
    if (apiKey == null || apiKey.isBlank()) {
      throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "GEMINI_API_KEY manquante");
    }
  }

  @SuppressWarnings("rawtypes")
  protected Map generateContent(Map<String, Object> body) {
    try {
      return client
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
  }

  protected String geminiErrorDetail(RestClientResponseException e) {
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
  protected static String extractText(Map<?, ?> response) {
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

  @SuppressWarnings("unchecked")
  protected static String extractFinishReason(Map<?, ?> response) {
    Object candidates = response.get("candidates");
    if (!(candidates instanceof List<?> candidateList) || candidateList.isEmpty()) {
      return null;
    }
    Object first = candidateList.getFirst();
    if (!(first instanceof Map<?, ?> candidate)) {
      return null;
    }
    Object reason = candidate.get("finishReason");
    return reason instanceof String s ? s : null;
  }

  protected static String compactForLog(String text) {
    String compact = text.replaceAll("\\s+", " ").trim();
    return compact.length() <= 1200 ? compact : compact.substring(0, 1200) + "...";
  }

  protected static String stripCodeFence(String text) {
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

  protected static String textOrNull(JsonNode node) {
    if (node == null || node.isNull()) {
      return null;
    }
    String value = node.asText(null);
    return value == null || value.isBlank() ? null : value.trim();
  }

  protected static JsonNode field(JsonNode root, String... names) {
    if (root == null) {
      return null;
    }
    for (String name : names) {
      JsonNode value = root.get(name);
      if (value != null && !value.isMissingNode() && !value.isNull()) {
        return value;
      }
    }
    return null;
  }

  /** Defaults a blank/null target language to French and normalizes ISO 639-1 codes. */
  protected static String normalizeLanguage(String language) {
    if (language == null || language.isBlank()) {
      return "fr";
    }
    String normalized = language.trim().toLowerCase();
    return normalized.equals("zh-cn") ? "zh" : normalized;
  }
}
