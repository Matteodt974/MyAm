package com.uqam.inm5151.scan.dto;

import java.util.List;

public record LabelRequest(String rawText, List<String> allergies) {
}
