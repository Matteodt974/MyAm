package com.uqam.inm5151.scan.service;

import java.util.List;
import java.util.Locale;
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

    // vérifie si un régime alimentaire est compatible avec les tags du produit et
    // les noms des ingrédients.
    public boolean isDietCompatible(Diet diet, List<String> productTags, List<String> ingredientNames) {
        if (diet == null) {
            return false;
        }

        List<String> values = normalizeValues(productTags, ingredientNames);

        return switch (diet) {
            case VEGAN -> matchesPositive(values, "vegan") && !containsAny(values, VEGAN_BLOCKERS);
            case VEGETARIAN ->
                matchesPositive(values, "vegetarian", "vegan")
                        && !containsAny(values, VEGETARIAN_BLOCKERS);
            case PESCETARIAN ->
                matchesPositive(values, "pescetarian", "vegetarian", "vegan")
                        && !containsAny(values, PESCETARIAN_BLOCKERS);
            case OMNIVORE -> true;
            case HALAL -> matchesPositive(values, "halal") && !containsAny(values, HALAL_BLOCKERS);
            case KOSHER -> matchesPositive(values, "kosher") && !containsAny(values, KOSHER_BLOCKERS);
            case GLUTEN_FREE ->
                matchesPositive(values, "gluten free", "gluten-free")
                        && !containsAny(values, GLUTEN_BLOCKERS);
            case LACTOSE_FREE ->
                matchesPositive(values, "lactose free", "lactose-free")
                        && !containsAny(values, LACTOSE_BLOCKERS);
        };
    }

    // vérifie si un produit est compatible avec un régime alimentaire donné en
    // utilisant uniquement le tag du produit.
    public boolean isDietCompatible(Diet diet, String productDiet) {
        return isDietCompatible(diet, productDiet == null ? List.of() : List.of(productDiet), List.of());
    }

    private static final String[] VEGAN_BLOCKERS = {
            "milk", "dairy", "lactose", "cheese", "butter", "cream", "yoghurt", "yogurt",
            "casein", "whey", "egg", "eggs", "fish", "meat", "chicken", "beef", "pork",
            "gelatin", "gelatine", "honey", "animal"
    };

    private static final String[] VEGETARIAN_BLOCKERS = {
            "meat", "fish", "chicken", "beef", "pork", "turkey", "gelatin", "gelatine", "animal"
    };

    private static final String[] PESCETARIAN_BLOCKERS = {
            "meat", "chicken", "beef", "pork", "turkey", "gelatin", "gelatine", "animal"
    };

    private static final String[] HALAL_BLOCKERS = { "pork", "bacon", "ham", "alcohol", "wine", "beer" };

    private static final String[] KOSHER_BLOCKERS = { "pork", "bacon", "ham", "shellfish", "crab", "lobster" };

    private static final String[] GLUTEN_BLOCKERS = {
            "wheat", "barley", "rye", "oats", "oat", "gluten", "flour", "semolina", "malt", "couscous"
    };

    private static final String[] LACTOSE_BLOCKERS = {
            "milk", "dairy", "lactose", "cheese", "butter", "cream", "whey", "casein", "yoghurt", "yogurt"
    };

    private static List<String> normalizeValues(List<String> productTags, List<String> ingredientNames) {
        return java.util.stream.Stream.concat(
                productTags == null ? java.util.stream.Stream.empty() : productTags.stream(),
                ingredientNames == null ? java.util.stream.Stream.empty() : ingredientNames.stream())
                .filter(value -> value != null && !value.isBlank())
                .map(DietMatchService::normalize)
                .toList();
    }

    private static boolean matchesPositive(List<String> values, String... positiveTokens) {
        for (String value : values) {
            for (String token : positiveTokens) {
                if (value.contains(token)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean containsAny(List<String> values, String[] blockers) {
        for (String value : values) {
            for (String blocker : blockers) {
                if (value.contains(blocker)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static String normalize(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT).replace(':', ' ').replace('-', ' ');
    }

}
