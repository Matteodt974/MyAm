package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.uqam.inm5151.scan.dto.LabelIngredient;
import java.util.List;
import org.junit.jupiter.api.Test;

class IngredientParserTest {

  private final IngredientParser parser = new IngredientParser();

  @Test
  void parse_simpleList_returnsThreeIngredients() {
    List<LabelIngredient> ingredients = parser.parse("sugar, palm oil, cocoa powder");

    assertThat(ingredients)
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "palm oil", "cocoa powder");
    assertThat(ingredients).allMatch(i -> i.confidence() == null);
  }

  @Test
  void parse_withQuantities_returnsIngredientsWithoutQuantities() {
    List<LabelIngredient> ingredients = parser.parse("100g sugar, 5% cocoa, 1.2 mg salt");

    assertThat(ingredients)
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "cocoa", "salt");
  }

  @Test
  void parse_withPluralUnits_returnsIngredientsWithoutQuantities() {
    List<LabelIngredient> ingredients =
        parser.parse("2 cups sugar, 1 gallon milk, 3 tsps vanilla, 2 quarts water, 1 pint cream");

    assertThat(ingredients)
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "milk", "vanilla", "water", "cream");
  }

  @Test
  void parse_withParentheses_returnsIngredientsWithoutParentheticalContent() {
    List<LabelIngredient> ingredients = parser.parse("sugar (beet), palm oil");

    assertThat(ingredients).extracting(LabelIngredient::name).containsExactly("sugar", "palm oil");
  }

  @Test
  void parse_withIngredientsPrefix_stripsPrefix() {
    List<LabelIngredient> ingredients = parser.parse("Ingredients: sugar, flour");

    assertThat(ingredients).extracting(LabelIngredient::name).containsExactly("sugar", "flour");
  }

  @Test
  void parse_withContainsPrefix_stripsPrefix() {
    List<LabelIngredient> ingredients = parser.parse("Contains: milk, soy");

    assertThat(ingredients).extracting(LabelIngredient::name).containsExactly("milk", "soy");
  }

  @Test
  void parse_variousSeparators_returnsFourIngredients() {
    List<LabelIngredient> ingredients = parser.parse("sugar; palm oil | cocoa\nvanilla");

    assertThat(ingredients)
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "palm oil", "cocoa", "vanilla");
  }

  @Test
  void parse_nullText_returnsEmptyList() {
    assertThat(parser.parse(null)).isEmpty();
  }

  @Test
  void parse_blankText_returnsEmptyList() {
    assertThat(parser.parse("   ")).isEmpty();
  }

  @Test
  void parse_onlyQuantitiesAndEmptyItems_returnsFilteredIngredients() {
    List<LabelIngredient> ingredients = parser.parse("100g, 5%, , , just water");

    assertThat(ingredients).extracting(LabelIngredient::name).containsExactly("just water");
  }
}
