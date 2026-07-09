package com.uqam.inm5151.scan.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class AllergenCrossMatchService {

  // Dictionnaire : synonymes français/latin -> forme canonique anglaise utilisée par Open Food
  // Facts
  private static final Map<String, String> SYNONYMS =
      Map.ofEntries(
          Map.entry("lait", "milk"),
          Map.entry("lactose", "milk"),
          Map.entry("caseine", "milk"),
          Map.entry("caséine", "milk"),
          Map.entry("beurre", "milk"),
          Map.entry("creme", "milk"),
          Map.entry("crème", "milk"),
          Map.entry("gluten", "gluten"),
          Map.entry("ble", "wheat"),
          Map.entry("blé", "wheat"),
          Map.entry("froment", "wheat"),
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

  // Trouve les allergènes du produit qui correspondent au profil utilisateur
  // (présence explicite)
  public List<String> findMatches(List<String> allergensTags, List<String> userAllergies) {
    return match(allergensTags, userAllergies);
  }

  // Trouve les traces du produit qui correspondent au profil utilisateur
  // (contamination croisée)
  public List<String> findTraces(List<String> tracesTags, List<String> userAllergies) {
    return match(tracesTags, userAllergies);
  }

  // Retourne les tags qui ne correspondent à aucune allergie connue du
  // dictionnaire
  public List<String> findUndetermined(List<String> allergensTags, List<String> userAllergies) {
    if (allergensTags == null || allergensTags.isEmpty()) {
      return List.of();
    }

    List<String> undetermined = new ArrayList<>();
    for (String tag : allergensTags) {
      String normalizedTag = normalizeTag(tag);
      boolean knownInDictionary =
          SYNONYMS.containsValue(normalizedTag) || SYNONYMS.containsKey(normalizedTag);
      boolean matchesUserAllergy = !match(List.of(tag), userAllergies).isEmpty();

      if (!knownInDictionary && !matchesUserAllergy) {
        undetermined.add(normalizedTag);
      }
    }
    return undetermined;
  }

  public List<String> findMatchesInIngredients(
      List<String> ingredients, List<String> userAllergies) {
    if (userAllergies == null || userAllergies.isEmpty()) return List.of();
    List<String> result = new ArrayList<>();
    for (String ingredient : ingredients) {
      String lower = ingredient.toLowerCase().trim();
      for (String allergy : userAllergies) {
        String normalizedAllergy = normalizeAllergy(allergy);
        boolean matched = false;
        for (String word : lower.split("\\s+")) {
          String mapped = SYNONYMS.getOrDefault(word, word);
          if (mapped.equals(normalizedAllergy)) {
            matched = true;
            break;
          }
        }
        if (matched) {
          result.add(lower);
          break;
        }
      }
    }
    return result;
  }

  // SAFE = aucun match, WARNING = traces seulement, DANGER = allergène présent
  public String riskLevel(List<String> matched, List<String> traces, List<String> undetermined) {
    if (!matched.isEmpty()) return "DANGER";
    if (!traces.isEmpty() || !undetermined.isEmpty()) return "WARNING";
    return "SAFE";
  }

  private List<String> match(List<String> tags, List<String> userAllergies) {
    if (userAllergies == null || userAllergies.isEmpty()) {
      return List.of();
    }

    List<String> result = new ArrayList<>();
    for (String tag : tags) {
      String normalizedTag = normalizeTag(tag);
      for (String allergy : userAllergies) {
        String normalizedAllergy = normalizeAllergy(allergy);
        if (TagMatcher.containsWord(List.of(normalizedTag), normalizedAllergy)
            || TagMatcher.containsWord(List.of(normalizedAllergy), normalizedTag)) {
          result.add(normalizedTag);
          break;
        }
      }
    }
    return result;
  }

  // Normalise un tag OFF : "en:tree-nuts" -> "tree nuts"
  private String normalizeTag(String tag) {
    int idx = tag.indexOf(':');
    String value = idx >= 0 ? tag.substring(idx + 1) : tag;
    return TagMatcher.normalize(value);
  }

  // Normalise une allergie utilisateur : "lait" -> "milk" via le dictionnaire
  private String normalizeAllergy(String allergy) {
    String lower = allergy.toLowerCase().trim();
    return SYNONYMS.getOrDefault(lower, lower);
  }
}
