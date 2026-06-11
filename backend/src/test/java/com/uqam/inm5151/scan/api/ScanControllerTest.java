package com.uqam.inm5151.scan.api;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Tests de l'endpoint UC5 — POST /v1/scan/dish.
 *
 * <p>Contexte complet ({@code @SpringBootTest}) : fiable et identique a celui qui
 * tourne en prod. L'endpoint /dish ne fait aucun appel reseau, et on ne teste pas
 * /barcode ici (il appellerait Open Food Facts). Le contrat JSON (cles, status,
 * 400 sur non-image) doit rester identique au backend FastAPI
 * (backend/tests/test_scan.py).</p>
 */
@SpringBootTest
@AutoConfigureMockMvc
class ScanControllerTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void dishAcceptsImage() throws Exception {
        var file = new MockMultipartFile(
                "image", "plat.jpg", "image/jpeg", new byte[] {1, 2, 3});

        mvc.perform(multipart("/v1/scan/dish").file(file))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.filename").value("plat.jpg"))
                .andExpect(jsonPath("$.content_type").value("image/jpeg"))
                .andExpect(jsonPath("$.size_bytes").value(3))
                .andExpect(jsonPath("$.status").value("not_implemented"))
                .andExpect(jsonPath("$.candidates").isEmpty());
    }

    @Test
    void dishRejectsNonImage() throws Exception {
        var file = new MockMultipartFile(
                "image", "notes.txt", "text/plain", "hello".getBytes());

        mvc.perform(multipart("/v1/scan/dish").file(file))
                .andExpect(status().isBadRequest());
    }
}
