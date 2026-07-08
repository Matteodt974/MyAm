package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Client Gemini dedie a UC-06 : detection de la langue d'une liste d'ingredients et traduction vers
 * l'anglais si necessaire.
 */
@Service
public class GeminiLabelClient extends AbstractGeminiClient {

  private static final Logger log = LoggerFactory.getLogger(GeminiLabelClient.class);

  private static final String PROMPT_TEMPLATE =
      """
            Detect the language of the following ingredient list and translate it to English if it is not already English.
            Return ONLY a JSON object with this exact shape:
            {"language":"<iso-639-1 code>","translated_text":"<english text>","is_english":true|false}
            Text: \"\"\"%s\"\"\"
            """;

  public GeminiLabelClient(AppProperties props, ObjectMapper objectMapper) {
    super(props, objectMapper);
  }

  public TranslationResult detectAndTranslate(String text) {
    requireApiKey();

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

    Map<?, ?> response = generateContent(body);
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

  private static JsonNode field(JsonNode root, String name) {
    if (root == null) {
      return null;
    }
    JsonNode value = root.get(name);
    return value != null && !value.isMissingNode() && !value.isNull() ? value : null;
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

  public record TranslationResult(String language, String translatedText, boolean english) {}
}
