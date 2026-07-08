package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.dto.LabelAnalysisResponse;
import com.uqam.inm5151.scan.dto.LabelIngredient;
import com.uqam.inm5151.scan.service.GeminiLabelClient.TranslationResult;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LabelAnalysisServiceTest {

  @Mock private GeminiLabelClient gemini;

  private final IngredientParser parser = new IngredientParser();
  private final AllergenCrossMatchService allergenCrossMatch = new AllergenCrossMatchService();

  @Test
  void analyze_englishText_returnsNotTranslatedWithSameTextAndParsedIngredients() {
    String text = "sugar, palm oil";
    when(gemini.detectAndTranslate(text, "en"))
        .thenReturn(new TranslationResult("en", text, List.of("sugar", "palm oil"), true));

    LabelAnalysisResponse response = service().analyze(text, "en", List.of());

    assertThat(response.originalLanguage()).isEqualTo("en");
    assertThat(response.translated()).isFalse();
    assertThat(response.translatedText()).isEqualTo(text);
    assertThat(response.ingredients())
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "palm oil");
  }

  @Test
  void analyze_frenchText_returnsTranslatedWithTranslatedText() {
    String text = "sucre, huile de palme";
    String translated = "sugar, palm oil";
    when(gemini.detectAndTranslate(text, "en"))
        .thenReturn(new TranslationResult("fr", translated, List.of("sugar", "palm oil"), false));

    LabelAnalysisResponse response = service().analyze(text, "en", List.of());

    assertThat(response.originalLanguage()).isEqualTo("fr");
    assertThat(response.translated()).isTrue();
    assertThat(response.translatedText()).isEqualTo(translated);
    assertThat(response.ingredients())
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "palm oil");
  }

  @Test
  void analyze_noStructuredIngredients_fallsBackToRegexParser() {
    String text = "sucre, huile de palme";
    String translated = "sugar, palm oil";
    when(gemini.detectAndTranslate(text, "en"))
        .thenReturn(new TranslationResult("fr", translated, List.of(), false));

    LabelAnalysisResponse response = service().analyze(text, "en", List.of());

    assertThat(response.ingredients())
        .extracting(LabelIngredient::name)
        .containsExactly("sugar", "palm oil");
  }

  @Test
  void analyze_nullText_throwsIllegalArgumentException() {
    assertThatThrownBy(() -> service().analyze(null, "en", List.of()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("requis");
  }

  @Test
  void analyze_blankText_throwsIllegalArgumentException() {
    assertThatThrownBy(() -> service().analyze("   ", "en", List.of()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("requis");
  }

  @Test
  void analyze_unsupportedLanguage_throwsUnsupportedLanguageException() {
    String text = "some text";
    when(gemini.detectAndTranslate(any(), any()))
        .thenThrow(new UnsupportedLanguageException("Langue non identifiable"));

    assertThatThrownBy(() -> service().analyze(text, "en", List.of()))
        .isInstanceOf(UnsupportedLanguageException.class)
        .hasMessageContaining("non identifiable");
  }

  @Test
  void analyze_matchingAllergy_returnsDangerRiskAndMatchedAllergen() {
    String text = "lait, sucre";
    when(gemini.detectAndTranslate(text, "en"))
        .thenReturn(new TranslationResult("en", text, List.of("milk", "sugar"), true));

    LabelAnalysisResponse response = service().analyze(text, "en", List.of("lait"));

    assertThat(response.riskLevel()).isEqualTo("DANGER");
    assertThat(response.matchedAllergens()).containsExactly("milk");
  }

  @Test
  void analyze_noMatchingAllergy_returnsSafeRiskAndNoMatches() {
    String text = "sugar, palm oil";
    when(gemini.detectAndTranslate(text, "en"))
        .thenReturn(new TranslationResult("en", text, List.of("sugar", "palm oil"), true));

    LabelAnalysisResponse response = service().analyze(text, "en", null);

    assertThat(response.riskLevel()).isEqualTo("SAFE");
    assertThat(response.matchedAllergens()).isEmpty();
  }

  private LabelAnalysisService service() {
    return new LabelAnalysisService(gemini, parser, allergenCrossMatch);
  }
}
