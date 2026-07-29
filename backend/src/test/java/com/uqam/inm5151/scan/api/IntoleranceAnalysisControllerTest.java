package com.uqam.inm5151.scan.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse;
import com.uqam.inm5151.scan.service.IntoleranceAnalysisService;
import com.uqam.inm5151.scan.service.IntoleranceRuleEngine;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class IntoleranceAnalysisControllerTest {

  @Autowired private MockMvc mvc;

  @MockBean private IntoleranceAnalysisService analysis;

  @Test
  @WithMockUser(username = "user@test.com")
  void analyze_validRequest_returnsReport() throws Exception {
    when(analysis.analyze(eq("user@test.com"), any()))
        .thenReturn(
            new IntoleranceAnalysisResponse(
                IntoleranceAnalysisResponse.STATUS_OK,
                null,
                new IntoleranceAnalysisResponse.BristolSummary(
                    1, java.util.Map.of(6, 1), "DIARRHEE", 0, 1, 0),
                List.of("Irritant alimentaire possible identifié parmi vos scans récents"),
                List.of(),
                IntoleranceRuleEngine.MEDICAL_DISCLAIMER));

    mvc.perform(
            post("/v1/analysis/intolerance")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"profileId\":7,\"foodItems\":[{\"name\":\"Lait\",\"consumedAt\":\"2026-07-27T06:00:00Z\","
                        + "\"allergens\":[\"lait\"],\"scanType\":\"barcode\"}]}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("OK"))
        .andExpect(jsonPath("$.bristolSummary.dominantProfile").value("DIARRHEE"))
        .andExpect(jsonPath("$.medicalDisclaimer").isNotEmpty());
  }

  @Test
  @WithMockUser(username = "user@test.com")
  void analyze_missingFoodItems_returnsBadRequest() throws Exception {
    mvc.perform(
            post("/v1/analysis/intolerance").contentType(MediaType.APPLICATION_JSON).content("{}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  @WithMockUser(username = "user@test.com")
  void analyze_blankFoodName_returnsBadRequest() throws Exception {
    mvc.perform(
            post("/v1/analysis/intolerance")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"profileId\":7,\"foodItems\":[{\"name\":\"\",\"consumedAt\":\"2026-07-27T06:00:00Z\"}]}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void analyze_withoutAuthentication_returnsUnauthorized() throws Exception {
    mvc.perform(
            post("/v1/analysis/intolerance")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"profileId\":7,\"foodItems\":[]}"))
        .andExpect(status().isUnauthorized());
  }
}
