package com.uqam.inm5151.scan.service;

import org.springframework.stereotype.Service;
import java.util.List;
import java.util.ArrayList;

@Service
public class IngredientExtractorService {

    public List<String> extract(String rawText) {
        String lower = rawText.toLowerCase();
        int start = lower.indexOf("ingrédients");
        if (start == -1)
            start = lower.indexOf("ingredients");
        if (start == -1)
            start = lower.indexOf("contient");
        if (start == -1)
            return List.of();

        String section = rawText.substring(start);
        int end = section.toLowerCase().indexOf("valeurs nutritionnelles");
        if (end == -1)
            end = section.toLowerCase().indexOf("nutritional");
        if (end == -1)
            end = section.toLowerCase().indexOf("conservation");
        if (end != -1)
            section = section.substring(0, end);

        section = section.replaceFirst("(?i)ingr[eé]dients\\s*[:;]?\\s*", "");

        List<String> result = new ArrayList<>();
        for (String part : section.split("[,;]")) {
            String clean = part.strip()
                    .replaceAll("\\(.*?\\)", "")
                    .replaceAll("[0-9]+\\.?[0-9]*\\s*%", "")
                    .replaceAll("[.!?]+$", "")
                    .strip();
            if (!clean.isEmpty())
                result.add(clean);
        }
        return result;

    }
}
