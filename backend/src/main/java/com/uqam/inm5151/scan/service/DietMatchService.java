package com.uqam.inm5151.scan.service;

public class DietMatchService {
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
