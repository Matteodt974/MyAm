package com.uqam.inm5151.scan.service;

import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;

@Service
public class AllergenCrossMatchService {

    public List<String> findMatches(List<String> allergensTags, List<String> userAllergies) {
        if (userAllergies == null || userAllergies.isEmpty()) {
            return List.of();
        }

        List<String> matched = new ArrayList<>();

        for (String tag : allergensTags) {
            String normalized = normalize(tag);
            for (String allergy : userAllergies) {
                if (normalized.contains(allergy) || allergy.contains(normalized)) {
                    matched.add(normalized);
                    break;
                }
            }
        }

        return matched;
    }

    private String normalize(String tag) {
        int idx = tag.indexOf(':');
        String value = idx >= 0 ? tag.substring(idx + 1) : tag;
        return value.replace('-', ' ').toLowerCase().trim();
    }

    public String riskLevel(List<String> matched) {
        if (matched.isEmpty()) {
            return "SAFE";
        }
        return "DANGER";
    }
}
