package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.dto.LabelIngredient;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;

/**
 * Parse un texte d'ingredients en anglais en une liste normalisee de {@link LabelIngredient}.
 *
 * <p>Regles simples : decoupage sur les separateurs courants, nettoyage des quantites, des
 * parentheses et des prefixes inutiles.
 */
@Service
public class IngredientParser {

  private static final Pattern SEPARATORS = Pattern.compile("[,;|•\\n]");

  /**
   * Supprime les quantites type "100g", "5%", "1.2 mg", "2 oz", "2 cups", "1 gallon", etc.
   *
   * <p>Les alternatives les plus longues/specifiques doivent precéder leurs prefixes (ex.
   * "gallons?" avant "g", "lb" avant "l") : l'alternance regex retient la premiere alternative qui
   * matche, donc un ordre inverse ne consommerait que le prefixe et laisserait un residu ("s",
   * "allon", ...) colle a l'ingredient suivant.
   */
  private static final Pattern QUANTITY =
      Pattern.compile(
          "\\b\\d+(?:\\.\\d+)?\\s*(?:fl\\s*oz|mcg|µg|mg|kg|tbsps?|tsps?|cups?|pints?|quarts?|gallons?|lb|oz|ml|l|%|g)",
          Pattern.CASE_INSENSITIVE);

  /** Contenu entre parentheses (y compris les parentheses). */
  private static final Pattern PARENTHESIS = Pattern.compile("\\([^)]*\\)");

  /** Prefixes inutiles en debut d'ingredient. */
  private static final Pattern[] PREFIXES = {
    Pattern.compile("^ingredients?\\s*[:：]\\s*", Pattern.CASE_INSENSITIVE),
    Pattern.compile("^contains?\\s*[:：]\\s*", Pattern.CASE_INSENSITIVE),
    Pattern.compile("^may contain\\s*[:：]\\s*", Pattern.CASE_INSENSITIVE),
  };

  public List<LabelIngredient> parse(String text) {
    if (text == null || text.isBlank()) {
      return List.of();
    }

    String[] rawItems = SEPARATORS.split(text);
    List<LabelIngredient> ingredients = new ArrayList<>(rawItems.length);
    for (String item : rawItems) {
      String cleaned = clean(item);
      if (cleaned != null) {
        ingredients.add(new LabelIngredient(cleaned, null));
      }
    }
    return ingredients;
  }

  private static String clean(String item) {
    String cleaned = item.trim().toLowerCase();
    if (cleaned.isBlank()) {
      return null;
    }

    cleaned = removePrefixes(cleaned);
    cleaned = PARENTHESIS.matcher(cleaned).replaceAll(" ").trim();
    cleaned = QUANTITY.matcher(cleaned).replaceAll(" ").trim();

    // Supprime les espaces multiples introduits par les nettoyages.
    cleaned = cleaned.replaceAll("\\s+", " ").trim();

    if (cleaned.isBlank()) {
      return null;
    }
    return cleaned;
  }

  private static String removePrefixes(String value) {
    String result = value;
    for (Pattern prefix : PREFIXES) {
      result = prefix.matcher(result).replaceFirst("");
    }
    return result.trim();
  }
}
