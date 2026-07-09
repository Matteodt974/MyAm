package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Client Gemini dedie a UC-06 : detection de la langue d'une liste d'ingredients et traduction vers
 * la langue cible choisie par l'utilisateur.
 */
@Service
public class GeminiLabelClient extends AbstractGeminiClient {

  private static final Logger log = LoggerFactory.getLogger(GeminiLabelClient.class);

  private static final String PROMPT_TEMPLATE =
      """
            Extract the ingredient list from the following OCR-scanned food label text. The text may
            contain, besides the ingredient list, unrelated content such as: manufacturer name and
            address, postal/zip code, copyright or legal notices, distributor lines, nutrition facts
            figures, allergen "Contains"/"May contain" statements, marketing text, or packaging
            instructions (e.g. "OPENING").

            Steps:
            1. Detect the primary language the ingredient list itself is written in.
            2. Extract ONLY the actual ingredient list content (the comma/semicolon-separated items,
               usually introduced by "Ingredients:" or "Ingredients :"). Discard everything else:
               addresses, postal codes, company/brand names, copyright notices, distributor lines,
               allergen statements, nutrition facts, and any unrelated packaging text.
            3. If the same ingredient list appears more than once (e.g. duplicated in another
               language on bilingual packaging), return it only once.
            4. Translate the extracted ingredient list into the target language (ISO 639-1: %s) if it
               is not already written in that language.
            5. Split the translated list into individual ingredient names, removing quantities, units
               and parenthetical notes from each one.

            Return ONLY a JSON object with this exact shape:
            {"language":"<iso-639-1 code of the ORIGINAL text>","translated_text":"<cleaned ingredient list in the target language, comma separated>","ingredients":["ingredient one","ingredient two"],"is_target_language":true|false}
            Text: \"\"\"%s\"\"\"
            """;

  public GeminiLabelClient(AppProperties props, ObjectMapper objectMapper) {
    super(props, objectMapper);
  }

  public TranslationResult detectAndTranslate(String text, String targetLanguage) {
    requireApiKey();

    String target = normalizeLanguage(targetLanguage);

    Map<String, Object> body =
        Map.of(
            "contents",
                List.of(
                    Map.of(
                        "role",
                        "user",
                        "parts",
                        List.of(Map.of("text", PROMPT_TEMPLATE.formatted(target, text))))),
            "generationConfig",
                Map.of(
                    "temperature", 0,
                    "response_mime_type", "application/json",
                    "maxOutputTokens", 4096));

    Map<?, ?> response = generateContent(body);
    return parseResponse(text, response);
  }

  private TranslationResult parseResponse(String originalText, Map<?, ?> response) {
    String text = extractText(response);
    if (text == null || text.isBlank()) {
      throw new GeminiDishAnalysisException("Gemini n'a pas retourne de JSON");
    }
    log.info(
        "Gemini label JSON (finishReason={}): {}",
        extractFinishReason(response),
        compactForLog(text));

    try {
      JsonNode root = objectMapper.readTree(stripCodeFence(text));
      String language = textOrNull(field(root, "language"));
      String translatedText = textOrNull(field(root, "translated_text"));
      List<String> ingredients = stringList(field(root, "ingredients"));
      boolean matchesTarget = booleanOrFalse(field(root, "is_target_language"));

      if (language == null || language.isBlank()) {
        throw new UnsupportedLanguageException("Langue non identifiable");
      }

      String extracted =
          translatedText != null && !translatedText.isBlank() ? translatedText : originalText;

      if (!matchesTarget && (translatedText == null || translatedText.isBlank())) {
        throw new GeminiDishAnalysisException("Gemini n'a pas fourni de traduction");
      }

      return new TranslationResult(language.toLowerCase(), extracted, ingredients, matchesTarget);
    } catch (UnsupportedLanguageException e) {
      throw e;
    } catch (Exception e) {
      throw new GeminiDishAnalysisException("JSON Gemini invalide", e);
    }
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

  private static List<String> stringList(JsonNode node) {
    if (node == null || !node.isArray()) {
      return List.of();
    }
    List<String> values = new ArrayList<>();
    for (JsonNode item : node) {
      String value = textOrNull(item);
      if (value != null) {
        values.add(value);
      }
    }
    return values;
  }

  public record TranslationResult(
      String language, String translatedText, List<String> ingredients, boolean matchesTarget) {}
}
