package com.uqam.inm5151.scan.service;

import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class DietMatchService {

    // Check if ANY of the user's diets is compatible with ANY of the product's
    // labels
    public boolean isUserDietsCompatible(List<Diet> userDiets, List<String> productLabels) {
        if (userDiets == null || userDiets.isEmpty() || productLabels == null || productLabels.isEmpty()) {
            return true; // No restrictions = everything is compatible
        }

        for (Diet diet : userDiets) {
            for (String label : productLabels) {
                if (isDietCompatible(diet, label)) {
                    return true; // Found at least one compatible match
                }
            }
        }
        return false; // No compatible match found
    }

    // Check if a single diet is compatible with a single product label
    public boolean isDietCompatible(Diet diet, String productDiet) {
        if (diet == null || productDiet == null) {
            return false;
        }

        switch (diet) {
            case VEGAN:
                return productDiet.equalsIgnoreCase("vegan");
            case VEGETARIAN:
                return productDiet.equalsIgnoreCase("vegetarian") || productDiet.equalsIgnoreCase("vegan");
            case PESCETARIAN:
                return productDiet.equalsIgnoreCase("pescetarian") || productDiet.equalsIgnoreCase("vegetarian")
                        || productDiet.equalsIgnoreCase("vegan");
            case OMNIVORE:
                return true;
            case HALAL:
                return productDiet.equalsIgnoreCase("halal");
            case KOSHER:
                return productDiet.equalsIgnoreCase("kosher");
            case GLUTEN_FREE:
                return productDiet.equalsIgnoreCase("gluten-free");
            case LACTOSE_FREE:
                return productDiet.equalsIgnoreCase("lactose-free");
            default:
                return false;
        }
    }

}
