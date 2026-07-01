package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.ALWAYS)
public record LabelIngredient(String name, Double confidence) {}
