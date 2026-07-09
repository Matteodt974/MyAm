package com.uqam.inm5151.scan.service;

import java.util.Optional;

public enum Diet {
  VEGAN,
  VEGETARIAN,
  PESCETARIAN,
  OMNIVORE,
  HALAL,
  KOSHER,
  GLUTEN_FREE,
  LACTOSE_FREE;

  public static Optional<Diet> tryParse(String value) {
    if (value == null || value.isBlank()) {
      return Optional.empty();
    }
    try {
      return Optional.of(Diet.valueOf(value.trim()));
    } catch (IllegalArgumentException e) {
      return Optional.empty();
    }
  }
}
