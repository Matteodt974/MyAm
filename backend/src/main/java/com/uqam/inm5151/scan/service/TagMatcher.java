package com.uqam.inm5151.scan.service;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Shared text normalization and word-boundary matching for OFF tags / ingredient text, used by both
 * {@link AllergenCrossMatchService} and {@link DietMatchService}.
 */
public final class TagMatcher {

  private static final Map<String, String> CANONICAL_TERMS =
      Map.ofEntries(
          Map.entry("lait", "milk"),
          Map.entry("lactose", "milk"),
          Map.entry("caseine", "milk"),
          Map.entry("caséine", "milk"),
          Map.entry("beurre", "milk"),
          Map.entry("creme", "milk"),
          Map.entry("crème", "milk"),
          Map.entry("fromage", "cheese"),
          Map.entry("yaourt", "yogurt"),
          Map.entry("petit lait", "whey"),
          Map.entry("gluten", "gluten"),
          Map.entry("ble", "wheat"),
          Map.entry("blé", "wheat"),
          Map.entry("froment", "wheat"),
          Map.entry("farine", "flour"),
          Map.entry("seigle", "rye"),
          Map.entry("orge", "barley"),
          Map.entry("avoine", "oats"),
          Map.entry("noix", "nuts"),
          Map.entry("noisette", "nuts"),
          Map.entry("amande", "nuts"),
          Map.entry("cacahuete", "peanuts"),
          Map.entry("cacahuète", "peanuts"),
          Map.entry("arachide", "peanuts"),
          Map.entry("soja", "soybeans"),
          Map.entry("soya", "soybeans"),
          Map.entry("oeuf", "eggs"),
          Map.entry("œuf", "eggs"),
          Map.entry("poisson", "fish"),
          Map.entry("viande", "meat"),
          Map.entry("poulet", "chicken"),
          Map.entry("boeuf", "beef"),
          Map.entry("bœuf", "beef"),
          Map.entry("porc", "pork"),
          Map.entry("jambon", "ham"),
          Map.entry("gelatine", "gelatin"),
          Map.entry("gélatine", "gelatin"),
          Map.entry("miel", "honey"),
          Map.entry("vin", "wine"),
          Map.entry("biere", "beer"),
          Map.entry("bière", "beer"),
          Map.entry("crustace", "crustaceans"),
          Map.entry("crustacé", "crustaceans"),
          Map.entry("mollusque", "molluscs"),
          Map.entry("celeri", "celery"),
          Map.entry("céleri", "celery"),
          Map.entry("moutarde", "mustard"),
          Map.entry("sesame", "sesame"),
          Map.entry("sésame", "sesame"),
          Map.entry("lupin", "lupin"),
          Map.entry("sulfite", "sulphur-dioxide-and-sulphites"));

  private TagMatcher() {}

  public static String normalize(String value) {
    return value == null
        ? ""
        : value
            .toLowerCase(Locale.ROOT)
            .replaceAll("[^\\p{L}\\p{N}]+", " ")
            .trim()
            .replaceAll("\\s+", " ");
  }

  public static List<String> tokenize(String normalizedValue) {
    if (normalizedValue == null || normalizedValue.isBlank()) {
      return List.of();
    }
    return Arrays.asList(normalizedValue.split(" "));
  }

  /** Maps a normalized French or English ingredient term to the shared English vocabulary. */
  public static String canonical(String value) {
    String normalized = normalize(value);
    return CANONICAL_TERMS.getOrDefault(normalized, normalized);
  }

  public static boolean isKnownTerm(String value) {
    String normalized = normalize(value);
    return CANONICAL_TERMS.containsKey(normalized) || CANONICAL_TERMS.containsValue(normalized);
  }

  /** Whole-word/phrase match: "milk" matches "coconut milk" but not "buttermilk". */
  public static boolean containsWord(List<String> normalizedValues, String phrase) {
    String needle = normalize(phrase);
    if (needle.isBlank()) {
      return false;
    }
    Pattern pattern = Pattern.compile("(^|\\s)" + Pattern.quote(needle) + "(\\s|$)");
    for (String value : normalizedValues) {
      if (value != null && pattern.matcher(value).find()) {
        return true;
      }
    }
    return false;
  }
}
