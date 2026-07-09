package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.config.AppProperties;
import com.uqam.inm5151.scan.dto.DishResponse;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

@ExtendWith(MockitoExtension.class)
class DishAnalysisServiceTest {

  @Mock private GeminiDishAnalysisClient gemini;

  @Mock private FoodDataCentralClient foodDataCentral;

  @Mock private DietMatchService dietMatchService;

  @Test
  void returnsIdentifiedDishWithIngredientsAndFoodDataMatches() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenReturn(
            new GeminiDishAnalysis(
                "Salade grecque",
                null,
                0.92,
                List.of(new GeminiDishAnalysis.DishCandidate("Salade grecque", 0.92)),
                List.of(new GeminiDishAnalysis.ProbableIngredient("tomate", 0.8))));
    when(foodDataCentral.search(any(), anyInt()))
        .thenReturn(
            List.of(
                new DishResponse.FoodDataMatch(
                    170457, "Tomatoes, red, raw", "SR Legacy", null, null)));

    DishResponse response = service().analyze(image(), null);

    assertThat(response.status()).isEqualTo("identified");
    assertThat(response.dishName()).isEqualTo("Salade grecque");
    assertThat(response.confidence()).isEqualTo(0.92);
    assertThat(response.dietStatus()).isEqualTo("unknown");
    assertThat(response.ingredients())
        .extracting(DishResponse.ProbableIngredient::name)
        .containsExactly("tomate");
    assertThat(response.foodDataMatches())
        .extracting(DishResponse.FoodDataMatch::fdcId)
        .containsExactly(170457);
  }

  @Test
  void returnsLowConfidenceStatusBelowThreshold() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenReturn(
            new GeminiDishAnalysis(
                "Ragout",
                null,
                0.42,
                List.of(new GeminiDishAnalysis.DishCandidate("Ragout", 0.42)),
                List.of()));

    DishResponse response = service().analyze(image(), null);

    assertThat(response.status()).isEqualTo("low_confidence");
    assertThat(response.dishName()).isEqualTo("Ragout");
    assertThat(response.message()).contains("incertaine");
  }

  @Test
  void returnsUnrecognizedWhenGeminiJsonIsInvalid() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenThrow(new GeminiDishAnalysisException("bad json"));

    DishResponse response = service().analyze(image(), null);

    assertThat(response.status()).isEqualTo("unrecognized");
    assertThat(response.dishName()).isNull();
    assertThat(response.ingredients()).isEmpty();
  }

  @Test
  void identifiedDishReportsCompatibleWhenDietMatchServiceApproves() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenReturn(
            new GeminiDishAnalysis(
                "Salade grecque",
                null,
                0.92,
                List.of(),
                List.of(new GeminiDishAnalysis.ProbableIngredient("tomate", 0.8))));
    when(dietMatchService.isUserDietsCompatible(any(), any(), any())).thenReturn(true);

    DishResponse response = service().analyze(image(), null, List.of(Diet.VEGAN));

    assertThat(response.dietCompatible()).isTrue();
    assertThat(response.dietStatus()).isEqualTo("compatible");
    assertThat(response.dietWarningDiet()).isNull();
  }

  @Test
  void identifiedDishReportsIncompatibleWhenDietMatchServiceRejects() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenReturn(
            new GeminiDishAnalysis(
                "Poulet roti",
                null,
                0.92,
                List.of(),
                List.of(new GeminiDishAnalysis.ProbableIngredient("poulet", 0.8))));
    when(dietMatchService.isUserDietsCompatible(any(), any(), any())).thenReturn(false);
    when(dietMatchService.firstIncompatibleDiet(any(), any(), any())).thenReturn(Diet.VEGAN);

    DishResponse response = service().analyze(image(), null, List.of(Diet.VEGAN));

    assertThat(response.dietCompatible()).isFalse();
    assertThat(response.dietStatus()).isEqualTo("incompatible");
    assertThat(response.dietWarningDiet()).isEqualTo("VEGAN");
  }

  @Test
  void lowConfidenceDishReportsUnknownDietStatusEvenWithUserDiets() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenReturn(new GeminiDishAnalysis("Ragout", null, 0.42, List.of(), List.of()));

    DishResponse response = service().analyze(image(), null, List.of(Diet.VEGAN));

    assertThat(response.dietStatus()).isEqualTo("unknown");
  }

  @Test
  void unrecognizedDishReportsUnknownDietStatusEvenWithUserDiets() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenThrow(new GeminiDishAnalysisException("bad json"));

    DishResponse response = service().analyze(image(), null, List.of(Diet.VEGAN));

    assertThat(response.status()).isEqualTo("unrecognized");
    assertThat(response.dietStatus()).isEqualTo("unknown");
  }

  @Test
  void keepsGeminiResultWhenFoodDataCentralFails() {
    when(gemini.analyze(any(), eq("image/jpeg"), any()))
        .thenReturn(
            new GeminiDishAnalysis(
                "Pates tomate",
                null,
                0.88,
                List.of(),
                List.of(new GeminiDishAnalysis.ProbableIngredient("tomate", 0.7))));
    when(foodDataCentral.search(any(), anyInt())).thenThrow(new RuntimeException("fdc down"));

    DishResponse response = service().analyze(image(), null);

    assertThat(response.status()).isEqualTo("identified");
    assertThat(response.dishName()).isEqualTo("Pates tomate");
    assertThat(response.foodDataMatches()).isEmpty();
  }

  @Test
  void geminiParserAcceptsCamelCaseDishNameAndStringConfidence() throws Exception {
    GeminiDishAnalysisClient client =
        new GeminiDishAnalysisClient(
            new AppProperties(
                "test", "test", "", "", "", "", "", "", "test-key", "gemini-test", "DEMO_KEY", ""),
            new ObjectMapper());
    var method = GeminiDishAnalysisClient.class.getDeclaredMethod("parseResponse", Map.class);
    method.setAccessible(true);
    Map<String, Object> response =
        Map.of(
            "candidates",
            List.of(
                Map.of(
                    "content",
                    Map.of(
                        "parts",
                        List.of(
                            Map.of(
                                "text",
                                """
                                                {
                                                  "dishName": "Pizza",
                                                  "confidence": "0.86",
                                                  "candidates": [],
                                                  "ingredients": []
                                                }
                                                """))))));

    GeminiDishAnalysis analysis = (GeminiDishAnalysis) method.invoke(client, response);

    assertThat(analysis.dishName()).isEqualTo("Pizza");
    assertThat(analysis.confidence()).isEqualTo(0.86);
  }

  private DishAnalysisService service() {
    return new DishAnalysisService(gemini, foodDataCentral, dietMatchService);
  }

  private static MockMultipartFile image() {
    return new MockMultipartFile("image", "plat.jpg", "image/jpeg", new byte[] {1, 2, 3});
  }
}
