package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisRequest.FoodItem;
import com.uqam.inm5151.scan.dto.IntoleranceAnalysisResponse;
import com.uqam.inm5151.scan.repository.DigestiveJournalEntryRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class IntoleranceAnalysisServiceTest {

  private static final String EMAIL = "user@test.com";
  private static final Instant NOW = Instant.parse("2026-07-27T12:00:00Z");

  @Mock private DigestiveJournalEntryRepository journalRepository;
  @Mock private EncryptionService encryption;
  @Mock private UserRepository users;

  private IntoleranceAnalysisService service() {
    return new IntoleranceAnalysisService(
        journalRepository, encryption, users, new IntoleranceRuleEngine());
  }

  private void givenUser() {
    User user = new User("Test", AccountType.STANDALONE);
    ReflectionTestUtils.setField(user, "id", 7L);
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(user));
  }

  private static FoodItem food(String name, Instant consumedAt) {
    return new FoodItem(name, consumedAt, List.of(), "barcode");
  }

  @Test
  void analyze_unknownUser_throwsUnauthorized() {
    when(users.findByEmail(EMAIL)).thenReturn(Optional.empty());

    assertThatThrownBy(
            () -> service().analyze(EMAIL, new IntoleranceAnalysisRequest(List.of()), NOW))
        .isInstanceOf(ResponseStatusException.class)
        .extracting(e -> ((ResponseStatusException) e).getStatusCode())
        .isEqualTo(HttpStatus.UNAUTHORIZED);
  }

  @Test
  void analyze_noJournalEntries_returnsNoJournalEntriesStatus() {
    givenUser();
    when(journalRepository.findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(eq(7L), any()))
        .thenReturn(List.of());

    IntoleranceAnalysisResponse response =
        service().analyze(EMAIL, new IntoleranceAnalysisRequest(List.of()), NOW);

    assertThat(response.status()).isEqualTo(IntoleranceAnalysisResponse.STATUS_NO_JOURNAL_ENTRIES);
    assertThat(response.message()).contains("journal digestif");
  }

  @Test
  void analyze_decryptsEpisodesAndDelegatesToEngine() {
    givenUser();
    byte[] encrypted = "enc-6".getBytes(StandardCharsets.UTF_8);
    when(journalRepository.findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(eq(7L), any()))
        .thenReturn(
            List.of(new DigestiveJournalEntry(7L, NOW.minusSeconds(3600), encrypted, null)));
    when(encryption.decrypt(encrypted)).thenReturn("6");

    IntoleranceAnalysisResponse response =
        service()
            .analyze(
                EMAIL,
                new IntoleranceAnalysisRequest(
                    List.of(
                        food("Lait", NOW.minusSeconds(2 * 3600)),
                        food("Pain", NOW.minusSeconds(3 * 3600)),
                        food("Pomme", NOW.minusSeconds(4 * 3600)))),
                NOW);

    assertThat(response.status()).isEqualTo(IntoleranceAnalysisResponse.STATUS_OK);
    assertThat(response.bristolSummary().diarrheaEpisodes()).isEqualTo(1);
    assertThat(response.possibleIrritants()).isNotEmpty();
  }

  @Test
  void analyze_foodItemsOlderThan72Hours_filteredOutServerSide() {
    givenUser();
    byte[] encrypted = "enc-4".getBytes(StandardCharsets.UTF_8);
    when(journalRepository.findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(eq(7L), any()))
        .thenReturn(
            List.of(new DigestiveJournalEntry(7L, NOW.minusSeconds(3600), encrypted, null)));
    when(encryption.decrypt(encrypted)).thenReturn("4");

    // 3 aliments envoyes mais 2 sont plus vieux que 72 h -> il n'en reste qu'un -> insuffisant.
    IntoleranceAnalysisResponse response =
        service()
            .analyze(
                EMAIL,
                new IntoleranceAnalysisRequest(
                    List.of(
                        food("Lait", NOW.minusSeconds(2 * 3600)),
                        food("Vieux pain", NOW.minusSeconds(80 * 3600)),
                        food("Vieille pomme", NOW.minusSeconds(90 * 3600)))),
                NOW);

    assertThat(response.status())
        .isEqualTo(IntoleranceAnalysisResponse.STATUS_INSUFFICIENT_FOOD_DATA);
  }

  @Test
  void analyze_futureDatedFoodItems_filteredOutServerSide() {
    givenUser();
    byte[] encrypted = "enc-4".getBytes(StandardCharsets.UTF_8);
    when(journalRepository.findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(eq(7L), any()))
        .thenReturn(
            List.of(new DigestiveJournalEntry(7L, NOW.minusSeconds(3600), encrypted, null)));
    when(encryption.decrypt(encrypted)).thenReturn("4");

    IntoleranceAnalysisResponse response =
        service()
            .analyze(
                EMAIL,
                new IntoleranceAnalysisRequest(
                    List.of(
                        food("Lait", NOW.minusSeconds(2 * 3600)),
                        food("Pain du futur", NOW.plusSeconds(3600)),
                        food("Pomme du futur", NOW.plusSeconds(7200)))),
                NOW);

    assertThat(response.status())
        .isEqualTo(IntoleranceAnalysisResponse.STATUS_INSUFFICIENT_FOOD_DATA);
  }
}
