package com.uqam.inm5151.scan.service;

import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class IngredientExtractorServiceTest {

    private final IngredientExtractorService service = new IngredientExtractorService();

    @Test
    void extract_returnsIngredients_whenLabelHasIngredientsSection() {
        String text = "Ingrédients : farine de blé, sucre, sel. Valeurs nutritionnelles pour 100g.";
        List<String> result = service.extract(text);
        assertFalse(result.isEmpty());
        assertTrue(result.contains("sucre"));
        assertTrue(result.contains("sel"));
    }

    @Test
    void extract_returnsEmpty_whenNoIngredientsSectionFound() {
        String text = "Valeurs nutritionnelles pour 100g. Protéines 5g, glucides 20g.";
        List<String> result = service.extract(text);
        assertTrue(result.isEmpty());
    }

    @Test
    void extract_worksWithEnglishKeyword() {
        String text = "Ingredients: wheat flour, sugar, butter.";
        List<String> result = service.extract(text);
        assertFalse(result.isEmpty());
        assertTrue(result.contains("wheat flour"));
    }

    @Test
    void extract_stripsPercentages() {
        String text = "Ingrédients : farine 60%, sucre 20%, sel.";
        List<String> result = service.extract(text);
        for (String ingredient : result) {
            assertFalse(ingredient.contains("%"));
        }
    }
}
