package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

class TagMatcherTest {

  @Test
  void normalizeReplacesPunctuationWithSpaces() {
    assertThat(TagMatcher.normalize("en:non-vegan")).isEqualTo("en non vegan");
  }

  @Test
  void normalizeHandlesNull() {
    assertThat(TagMatcher.normalize(null)).isEmpty();
  }

  @Test
  void containsWordMatchesWholeWord() {
    assertThat(TagMatcher.containsWord(List.of("milk protein"), "milk")).isTrue();
  }

  @Test
  void containsWordDoesNotMatchSubstringInsideEggplant() {
    assertThat(TagMatcher.containsWord(List.of("eggplant"), "egg")).isFalse();
  }

  @Test
  void containsWordDoesNotMatchSubstringInsideGoat() {
    assertThat(TagMatcher.containsWord(List.of("goat cheese"), "oat")).isFalse();
  }

  @Test
  void containsWordMatchesMultiWordPhrase() {
    assertThat(TagMatcher.containsWord(List.of("en non vegan"), "non vegan")).isTrue();
  }

  @Test
  void containsWordIsFalseWhenNoValues() {
    assertThat(TagMatcher.containsWord(List.of(), "milk")).isFalse();
  }
}
