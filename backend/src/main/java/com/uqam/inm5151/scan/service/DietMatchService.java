package com.uqam.inm5151.scan.service;

import java.util.List;
import java.util.Set;
import java.util.stream.Stream;
import org.springframework.stereotype.Service;

@Service
public class DietMatchService {

  // compare chaque diet au produit
  public boolean isUserDietsCompatible(
      List<Diet> userDiets, List<String> productTags, List<String> ingredientNames) {
    if (userDiets == null || userDiets.isEmpty()) {
      return true;
    }

    for (Diet diet : userDiets) {
      if (!isDietCompatible(diet, productTags, ingredientNames)) {
        return false;
      }
    }
    return true;
  }

  // renvoie le premier diet incompatible du profil utilisateur, ou null si tout est compatible
  public Diet firstIncompatibleDiet(
      List<Diet> userDiets, List<String> productTags, List<String> ingredientNames) {
    if (userDiets == null || userDiets.isEmpty()) {
      return null;
    }

    for (Diet diet : userDiets) {
      if (!isDietCompatible(diet, productTags, ingredientNames)) {
        return diet;
      }
    }
    return null;
  }

  // vérifie si un régime alimentaire est compatible avec les tags du produit et les noms des
  // ingrédients. Logique "compatible sauf si un blocker est trouvé" (comme
  // AllergenCrossMatchService traite deja les allergenes) : un plat/produit n'a pas besoin de
  // declarer explicitement "vegan"/"halal"/etc. pour etre traite comme compatible, il suffit
  // qu'aucun ingredient bloquant ne soit detecte.
  public boolean isDietCompatible(
      Diet diet, List<String> productTags, List<String> ingredientNames) {
    if (diet == null) {
      return false;
    }

    List<String> values = normalizeValues(productTags, ingredientNames);

    return switch (diet) {
      case VEGAN -> !hasNegativeTag(values, "vegan") && isBlockerFree(values, VEGAN_BLOCKERS);
      case VEGETARIAN ->
          !hasNegativeTag(values, "vegetarian") && isBlockerFree(values, VEGETARIAN_BLOCKERS);
      case PESCETARIAN -> isBlockerFree(values, PESCETARIAN_BLOCKERS);
      case OMNIVORE -> true;
      case HALAL -> isBlockerFree(values, HALAL_BLOCKERS);
      case KOSHER -> isBlockerFree(values, KOSHER_BLOCKERS);
      case GLUTEN_FREE -> isBlockerFree(values, GLUTEN_BLOCKERS);
      case LACTOSE_FREE -> isBlockerFree(values, LACTOSE_BLOCKERS);
    };
  }

  // vérifie si un produit est compatible avec un régime alimentaire donné en
  // utilisant uniquement le tag du produit.
  public boolean isDietCompatible(Diet diet, String productDiet) {
    return isDietCompatible(
        diet, productDiet == null ? List.of() : List.of(productDiet), List.of());
  }

  private static final String[] VEGAN_BLOCKERS = {
    "milk",
    "dairy",
    "lactose",
    "cheese",
    "butter",
    "cream",
    "yoghurt",
    "yogurt",
    "casein",
    "whey",
    "egg",
    "eggs",
    "fish",
    "meat",
    "chicken",
    "beef",
    "pork",
    "gelatin",
    "gelatine",
    "honey",
    "animal"
  };

  private static final String[] VEGETARIAN_BLOCKERS = {
    "meat", "fish", "chicken", "beef", "pork", "turkey", "gelatin", "gelatine", "animal"
  };

  private static final String[] PESCETARIAN_BLOCKERS = {
    "meat", "chicken", "beef", "pork", "turkey", "gelatin", "gelatine", "animal"
  };

  private static final String[] HALAL_BLOCKERS = {
    "pork", "bacon", "ham", "alcohol", "wine", "beer"
  };

  private static final String[] KOSHER_BLOCKERS = {
    "pork", "bacon", "ham", "shellfish", "crab", "lobster"
  };

  private static final String[] GLUTEN_BLOCKERS = {
    "wheat", "barley", "rye", "oats", "oat", "gluten", "flour", "semolina", "malt", "couscous"
  };

  private static final String[] LACTOSE_BLOCKERS = {
    "milk", "dairy", "lactose", "cheese", "butter", "cream", "whey", "casein", "yoghurt", "yogurt"
  };

  // Mots dont la presence juste avant/apres un blocker signale une negation ("egg free", "free
  // of gluten", "milk free") plutot qu'un vrai blocker.
  private static final Set<String> NEGATION_WORDS =
      Set.of("free", "without", "sans", "no", "non", "not");

  private static List<String> normalizeValues(
      List<String> productTags, List<String> ingredientNames) {
    return Stream.concat(
            productTags == null ? Stream.<String>empty() : productTags.stream(),
            ingredientNames == null ? Stream.<String>empty() : ingredientNames.stream())
        .filter(value -> value != null && !value.isBlank())
        .map(TagMatcher::normalize)
        .toList();
  }

  // Detecte le tag explicite d'Open Food Facts (ex: "en:non-vegan", "en:non-vegetarian") plutot
  // que de deviner a partir d'un mot-cle positif comme "vegan" : un tag qui dit explicitement
  // "non-vegan" contient lui-meme le mot "vegan", donc chercher ce mot comme preuve positive
  // matcherait aussi ce meme tag negatif.
  private static boolean hasNegativeTag(List<String> values, String dietName) {
    return TagMatcher.containsWord(values, "non " + dietName);
  }

  private static boolean isBlockerFree(List<String> values, String[] blockers) {
    for (String value : values) {
      List<String> tokens = TagMatcher.tokenize(value);
      for (int i = 0; i < tokens.size(); i++) {
        for (String blocker : blockers) {
          if (tokens.get(i).equals(blocker) && !isNegated(tokens, i)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  private static boolean isNegated(List<String> tokens, int index) {
    String previous = index > 0 ? tokens.get(index - 1) : null;
    String next = index + 1 < tokens.size() ? tokens.get(index + 1) : null;

    if ((previous != null && NEGATION_WORDS.contains(previous))
        || (next != null && NEGATION_WORDS.contains(next))) {
      return true;
    }

    // "free of milk", "free from gluten"
    return index > 1
        && "free".equals(tokens.get(index - 2))
        && ("of".equals(previous) || "from".equals(previous));
  }
}
