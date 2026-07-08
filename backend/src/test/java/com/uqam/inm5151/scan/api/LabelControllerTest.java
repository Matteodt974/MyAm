package com.uqam.inm5151.scan.api;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.uqam.inm5151.scan.dto.LabelAnalysisResponse;
import com.uqam.inm5151.scan.dto.LabelIngredient;
import com.uqam.inm5151.scan.service.LabelAnalysisService;
import com.uqam.inm5151.scan.service.UnsupportedLanguageException;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class LabelControllerTest {

  @Autowired private MockMvc mvc;

  @MockBean private LabelAnalysisService labelAnalysis;

  @Test
  void analyzeLabel_validRequest_returnsOkAndResponse() throws Exception {
    when(labelAnalysis.analyze("sugar, palm oil", null, null))
        .thenReturn(
            new LabelAnalysisResponse(
                "en",
                false,
                "sugar, palm oil",
                List.of(new LabelIngredient("sugar", null), new LabelIngredient("palm oil", null)),
                "SAFE",
                List.of()));

    mvc.perform(
            post("/v1/label/translate-and-structure")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"text\":\"sugar, palm oil\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.original_language").value("en"))
        .andExpect(jsonPath("$.translated").value(false))
        .andExpect(jsonPath("$.translated_text").value("sugar, palm oil"))
        .andExpect(jsonPath("$.ingredients[0].name").value("sugar"))
        .andExpect(jsonPath("$.ingredients[1].name").value("palm oil"));
  }

  @Test
  void analyzeLabel_blankText_returnsBadRequest() throws Exception {
    mvc.perform(
            post("/v1/label/translate-and-structure")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"text\":\"\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void analyzeLabel_unsupportedLanguage_returnsUnprocessableEntity() throws Exception {
    when(labelAnalysis.analyze("inconnu", null, null))
        .thenThrow(new UnsupportedLanguageException("Langue non supportee"));

    mvc.perform(
            post("/v1/label/translate-and-structure")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"text\":\"inconnu\"}"))
        .andExpect(status().isUnprocessableEntity());
  }
}
