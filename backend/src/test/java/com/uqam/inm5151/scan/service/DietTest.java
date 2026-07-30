package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class DietTest {

  @Test
  void tryParse_whenValidName_returnsEnum() {
    Optional<Diet> diet = Diet.tryParse("VEGAN");

    assertThat(diet).isPresent().contains(Diet.VEGAN);
  }

  @Test
  void tryParse_whenValidNameWithSurroundingSpaces_returnsEnum() {
    Optional<Diet> diet = Diet.tryParse("  HALAL  ");

    assertThat(diet).isPresent().contains(Diet.HALAL);
  }

  @Test
  void tryParse_whenUnknownName_returnsEmpty() {
    Optional<Diet> diet = Diet.tryParse("UNKNOWN_DIET");

    assertThat(diet).isEmpty();
  }

  @Test
  void tryParse_whenNullOrBlank_returnsEmpty() {
    assertThat(Diet.tryParse(null)).isEmpty();
    assertThat(Diet.tryParse("")).isEmpty();
    assertThat(Diet.tryParse("   ")).isEmpty();
  }

  @Test
  void parseAll_whenMixedValidAndInvalidValues_returnsOnlyValidEnums() {
    List<String> input = List.of("VEGAN", "UNKNOWN", "  GLUTEN_FREE  ", "");

    List<Diet> result = Diet.parseAll(input);

    assertThat(result).containsExactly(Diet.VEGAN, Diet.GLUTEN_FREE);
  }

  @Test
  void parseAll_whenNullOrEmptyList_returnsEmptyList() {
    assertThat(Diet.parseAll(null)).isEmpty();
    assertThat(Diet.parseAll(List.of())).isEmpty();
  }
}