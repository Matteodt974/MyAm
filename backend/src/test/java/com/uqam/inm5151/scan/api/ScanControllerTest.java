package com.uqam.inm5151.scan.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.uqam.inm5151.scan.dto.DishResponse;
import com.uqam.inm5151.scan.service.DishAnalysisService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class ScanControllerTest {

  @Autowired private MockMvc mvc;

  @MockBean private DishAnalysisService dishAnalysis;

  @Test
  void dishAcceptsImageAndReturnsAnalysis() throws Exception {
    var file = new MockMultipartFile("image", "plat.jpg", "image/jpeg", new byte[] {1, 2, 3});
    when(dishAnalysis.analyze(any()))
        .thenReturn(
            new DishResponse(
                "plat.jpg",
                "image/jpeg",
                3,
                "identified",
                "Plat identifie a partir de la photo.",
                "Salade grecque",
                0.91,
                List.of(new DishResponse.DishCandidate("Salade grecque", 0.91)),
                List.of(new DishResponse.ProbableIngredient("tomate", 0.84)),
                List.of(
                    new DishResponse.FoodDataMatch(
                        170457, "Tomatoes, red, raw", "SR Legacy", null, null))));

    mvc.perform(multipart("/v1/scan/dish").file(file))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.filename").value("plat.jpg"))
        .andExpect(jsonPath("$.content_type").value("image/jpeg"))
        .andExpect(jsonPath("$.size_bytes").value(3))
        .andExpect(jsonPath("$.status").value("identified"))
        .andExpect(jsonPath("$.dish_name").value("Salade grecque"))
        .andExpect(jsonPath("$.confidence").value(0.91))
        .andExpect(jsonPath("$.ingredients[0].name").value("tomate"))
        .andExpect(jsonPath("$.food_data_matches[0].fdc_id").value(170457));
  }

  @Test
  void dishRejectsNonImage() throws Exception {
    var file = new MockMultipartFile("image", "notes.txt", "text/plain", "hello".getBytes());

    mvc.perform(multipart("/v1/scan/dish").file(file)).andExpect(status().isBadRequest());
  }
}
