package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

class DietMatchServiceTest {

  private final DietMatchService service = new DietMatchService();

  @Test
  void veganIngredientMatchDoesNotFlagEggplant() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of(), List.of("eggplant"))).isTrue();
  }

  @Test
  void veganIngredientMatchFlagsEgg() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of(), List.of("egg"))).isFalse();
  }

  @Test
  void veganIngredientMatchFlagsEggWhites() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of(), List.of("egg whites"))).isFalse();
  }

  @Test
  void veganIngredientMatchFlagsMilkProtein() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of(), List.of("milk protein"))).isFalse();
  }

  @Test
  void veganTreatsEggFreeTagAsCompatible() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of("egg free"), List.of())).isTrue();
  }

  @Test
  void veganTreatsOffNonVeganTagAsIncompatible() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of("en:non-vegan"), List.of())).isFalse();
  }

  @Test
  void vegetarianTreatsOffNonVegetarianTagAsIncompatible() {
    assertThat(service.isDietCompatible(Diet.VEGETARIAN, List.of("en:non-vegetarian"), List.of()))
        .isFalse();
  }

  @Test
  void veganTagStillMatchesWhenExact() {
    assertThat(service.isDietCompatible(Diet.VEGAN, List.of("en:vegan"), List.of())).isTrue();
  }

  @Test
  void vegetarianWithExplicitTagAndNoBlockersMatches() {
    assertThat(service.isDietCompatible(Diet.VEGETARIAN, List.of("en:vegetarian"), List.of()))
        .isTrue();
  }

  @Test
  void lactoseFreeMatchesWhenNoLactoseBlockersArePresent() {
    assertThat(service.isDietCompatible(Diet.LACTOSE_FREE, List.of("en:fish"), List.of())).isTrue();
  }

  @Test
  void lactoseFreeFailsWhenLactoseBlockerIsPresent() {
    assertThat(
            service.isDietCompatible(
                Diet.LACTOSE_FREE, List.of("en:fish"), List.of("milk protein")))
        .isFalse();
  }

  @Test
  void lactoseFreeTagIsCompatibleWithoutRequiringPositiveKeyword() {
    assertThat(service.isDietCompatible(Diet.LACTOSE_FREE, List.of("en:lactose-free"), List.of()))
        .isTrue();
  }

  @Test
  void glutenFreeTagIsNotBlockedByItsOwnGlutenWord() {
    assertThat(service.isDietCompatible(Diet.GLUTEN_FREE, List.of("en:gluten-free"), List.of()))
        .isTrue();
  }

  @Test
  void glutenFreeIgnoresOatSubstringInGoatCheese() {
    assertThat(service.isDietCompatible(Diet.GLUTEN_FREE, List.of(), List.of("goat cheese")))
        .isTrue();
  }

  @Test
  void glutenFreeFailsWhenWheatIsPresent() {
    assertThat(service.isDietCompatible(Diet.GLUTEN_FREE, List.of(), List.of("wheat flour")))
        .isFalse();
  }

  @Test
  void halalCompatibleForDishPhotoWithNoExplicitTagAndNoBlocker() {
    assertThat(service.isDietCompatible(Diet.HALAL, List.of(), List.of("rice", "vegetables")))
        .isTrue();
  }

  @Test
  void halalFailsWhenPorkIsPresent() {
    assertThat(service.isDietCompatible(Diet.HALAL, List.of(), List.of("pork belly"))).isFalse();
  }

  @Test
  void kosherCompatibleForDishPhotoWithNoExplicitTagAndNoBlocker() {
    assertThat(service.isDietCompatible(Diet.KOSHER, List.of(), List.of("rice", "vegetables")))
        .isTrue();
  }

  @Test
  void omnivoreAlwaysCompatible() {
    assertThat(service.isDietCompatible(Diet.OMNIVORE, List.of(), List.of("pork belly"))).isTrue();
  }

  @Test
  void firstIncompatibleDietReturnsFirstFailingDiet() {
    Diet result =
        service.firstIncompatibleDiet(
            List.of(Diet.VEGAN, Diet.HALAL), List.of(), List.of("pork belly"));
    assertThat(result).isEqualTo(Diet.VEGAN);
  }

  @Test
  void firstIncompatibleDietReturnsNullWhenAllCompatible() {
    Diet result =
        service.firstIncompatibleDiet(List.of(Diet.VEGAN, Diet.HALAL), List.of(), List.of("rice"));
    assertThat(result).isNull();
  }
}
