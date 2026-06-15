package com.uqam.inm5151.scan.service;

import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class AllergenCrossMatchServiceTest {

    private final AllergenCrossMatchService service = new AllergenCrossMatchService();

    @Test
    void matchFound_whenAllergenMatchesUserAllergy() {
        List<String> allergensTags = List.of("en:milk", "en:nuts");
        List<String> userAllergies = List.of("milk");

        List<String> matched = service.findMatches(allergensTags, userAllergies);

        assertFalse(matched.isEmpty());
        assertTrue(matched.contains("milk"));
    }

    @Test
    void matchFound_whenUserAllergiesInFrench() {
        List<String> allergensTags = List.of("en:milk", "en:nuts");
        List<String> userAllergies = List.of("lait");

        List<String> matched = service.findMatches(allergensTags, userAllergies);

        assertFalse(matched.isEmpty());
        assertTrue(matched.contains("milk"));
    }

    @Test
    void noMatch_whenNoAllergenInUserProfile() {
        List<String> allergensTags = List.of("en:milk", "en:nuts");
        List<String> userAllergies = List.of("gluten");

        List<String> matched = service.findMatches(allergensTags, userAllergies);

        assertTrue(matched.isEmpty());
    }

    @Test
    void riskLevel_isDanger_whenMatchFound() {
        List<String> matched = List.of("milk");
        List<String> traces = List.of();
        assertEquals("DANGER", service.riskLevel(matched, traces, List.of()));
    }

    @Test
    void riskLevel_isWarning_whenTraceFound() {
        List<String> matched = List.of();
        List<String> traces = List.of("nuts");
        assertEquals("WARNING", service.riskLevel(matched, traces, List.of()));
    }

    @Test
    void riskLevel_isSafe_whenNoMatch() {
        List<String> matched = List.of();
        List<String> traces = List.of();
        assertEquals("SAFE", service.riskLevel(matched, traces, List.of()));
    }
}
