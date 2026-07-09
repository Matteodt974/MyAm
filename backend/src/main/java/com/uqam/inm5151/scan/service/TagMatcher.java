package com.uqam.inm5151.scan.service;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Shared text normalization and word-boundary matching for OFF tags / ingredient text, used by both
 * {@link AllergenCrossMatchService} and {@link DietMatchService}.
 */
public final class TagMatcher {

  private TagMatcher() {}

  public static String normalize(String value) {
    return value == null
        ? ""
        : value
            .toLowerCase(Locale.ROOT)
            .replaceAll("[^\\p{Alnum}]+", " ")
            .trim()
            .replaceAll("\\s+", " ");
  }

  public static List<String> tokenize(String normalizedValue) {
    if (normalizedValue == null || normalizedValue.isBlank()) {
      return List.of();
    }
    return Arrays.asList(normalizedValue.split(" "));
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
