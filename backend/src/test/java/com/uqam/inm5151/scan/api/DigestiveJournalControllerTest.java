package com.uqam.inm5151.scan.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.uqam.inm5151.scan.dto.DigestiveEntryResponse;
import com.uqam.inm5151.scan.service.DigestiveJournalService;
import java.time.Instant;
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
class DigestiveJournalControllerTest {

  private static final Instant OCCURRED_AT = Instant.parse("2026-07-26T08:00:00Z");

  @Autowired private MockMvc mvc;

  @MockBean private DigestiveJournalService journal;

  @Test
  @WithMockUser(username = "user@test.com")
  void create_validRequest_returnsCreated() throws Exception {
    when(journal.create(eq("user@test.com"), eq(7L), any()))
        .thenReturn(new DigestiveEntryResponse(1L, OCCURRED_AT, 6, "crampes", OCCURRED_AT));

    mvc.perform(
            post("/v1/digestive-journal")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"profileId\":7,\"bristolType\":6,\"occurredAt\":\"2026-07-26T08:00:00Z\","
                        + "\"notes\":\"crampes\"}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.id").value(1))
        .andExpect(jsonPath("$.bristolType").value(6))
        .andExpect(jsonPath("$.notes").value("crampes"));
  }

  @Test
  @WithMockUser(username = "user@test.com")
  void create_bristolTypeOutOfRange_returnsBadRequest() throws Exception {
    mvc.perform(
            post("/v1/digestive-journal")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"profileId\":7,\"bristolType\":9,\"occurredAt\":\"2026-07-26T08:00:00Z\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  @WithMockUser(username = "user@test.com")
  void create_futureOccurredAt_returnsBadRequest() throws Exception {
    mvc.perform(
            post("/v1/digestive-journal")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"profileId\":7,\"bristolType\":4,\"occurredAt\":\"2999-01-01T00:00:00Z\"}"))
        .andExpect(status().isBadRequest());
  }

  @Test
  void create_withoutAuthentication_returnsUnauthorized() throws Exception {
    mvc.perform(
            post("/v1/digestive-journal")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"profileId\":7,\"bristolType\":4,\"occurredAt\":\"2026-07-26T08:00:00Z\"}"))
        .andExpect(status().isUnauthorized());
  }

  @Test
  @WithMockUser(username = "user@test.com")
  void list_returnsEntries() throws Exception {
    when(journal.list(eq("user@test.com"), eq(7L), isNull()))
        .thenReturn(List.of(new DigestiveEntryResponse(1L, OCCURRED_AT, 2, null, OCCURRED_AT)));

    mvc.perform(get("/v1/digestive-journal").queryParam("profileId", "7"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$[0].bristolType").value(2));
  }

  @Test
  void list_withoutAuthentication_returnsUnauthorized() throws Exception {
    mvc.perform(get("/v1/digestive-journal").queryParam("profileId", "7"))
        .andExpect(status().isUnauthorized());
  }
}
