package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.DigestiveEntryRequest;
import com.uqam.inm5151.scan.dto.DigestiveEntryResponse;
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
class DigestiveJournalServiceTest {

  private static final String EMAIL = "user@test.com";
  private static final Instant OCCURRED_AT = Instant.parse("2026-07-26T08:00:00Z");

  @Mock private DigestiveJournalEntryRepository repository;
  @Mock private EncryptionService encryption;
  @Mock private UserRepository users;

  private DigestiveJournalService service() {
    return new DigestiveJournalService(repository, encryption, users);
  }

  private User userWithId(long id) {
    User user = new User("Test", AccountType.STANDALONE);
    ReflectionTestUtils.setField(user, "id", id);
    return user;
  }

  @Test
  void create_encryptsBristolTypeAndNotes() {
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(userWithId(7L)));
    when(encryption.encrypt("6")).thenReturn(bytes("enc-6"));
    when(encryption.encrypt("crampes")).thenReturn(bytes("enc-notes"));
    when(encryption.decrypt(bytes("enc-6"))).thenReturn("6");
    when(encryption.decrypt(bytes("enc-notes"))).thenReturn("crampes");
    when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    DigestiveEntryResponse response =
        service().create(EMAIL, 7L, new DigestiveEntryRequest(7L, 6, OCCURRED_AT, "crampes"));

    assertThat(response.bristolType()).isEqualTo(6);
    assertThat(response.notes()).isEqualTo("crampes");
    assertThat(response.occurredAt()).isEqualTo(OCCURRED_AT);
    verify(encryption).encrypt("6");
    verify(encryption).encrypt("crampes");
  }

  @Test
  void create_blankNotes_storedAsNull() {
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(userWithId(7L)));
    when(encryption.encrypt("4")).thenReturn(bytes("enc-4"));
    when(encryption.decrypt(bytes("enc-4"))).thenReturn("4");
    when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    DigestiveEntryResponse response =
        service().create(EMAIL, 7L, new DigestiveEntryRequest(7L, 4, OCCURRED_AT, "   "));

    assertThat(response.notes()).isNull();
  }

  @Test
  void create_unknownUser_throwsUnauthorized() {
    when(users.findByEmail(EMAIL)).thenReturn(Optional.empty());

    assertThatThrownBy(
            () -> service().create(EMAIL, 7L, new DigestiveEntryRequest(7L, 4, OCCURRED_AT, null)))
        .isInstanceOf(ResponseStatusException.class)
        .extracting(e -> ((ResponseStatusException) e).getStatusCode())
        .isEqualTo(HttpStatus.UNAUTHORIZED);
  }

  @Test
  void list_decryptsEntriesFromRepository() {
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(userWithId(7L)));
    DigestiveJournalEntry entry = new DigestiveJournalEntry(7L, OCCURRED_AT, bytes("enc-2"), null);
    when(repository.findForProfile(7L, 7L)).thenReturn(List.of(entry));
    when(encryption.decrypt(bytes("enc-2"))).thenReturn("2");

    List<DigestiveEntryResponse> entries = service().list(EMAIL, 7L, null);

    assertThat(entries).hasSize(1);
    assertThat(entries.getFirst().bristolType()).isEqualTo(2);
    assertThat(entries.getFirst().notes()).isNull();
  }

  @Test
  void list_withSince_usesTimeFilteredQuery() {
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(userWithId(7L)));
    Instant since = OCCURRED_AT.minusSeconds(3600);
    when(repository.findForProfileSince(7L, 7L, since)).thenReturn(List.of());

    assertThat(service().list(EMAIL, 7L, since)).isEmpty();
    verify(repository).findForProfileSince(7L, 7L, since);
  }

  @Test
  void list_childProfile_usesOwnerAndSelectedProfileIds() {
    User owner = userWithId(7L);
    User child = new User("Camille", AccountType.MANAGED);
    ReflectionTestUtils.setField(child, "id", 8L);
    child.setGuardianUserId(7L);
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(owner));
    when(users.findById(8L)).thenReturn(Optional.of(child));
    when(repository.findForProfile(7L, 8L)).thenReturn(List.of());

    assertThat(service().list(EMAIL, 8L, null)).isEmpty();

    verify(repository).findForProfile(7L, 8L);
  }

  @Test
  void list_profileOwnedByAnotherGuardian_throwsForbidden() {
    User child = new User("Autre enfant", AccountType.MANAGED);
    ReflectionTestUtils.setField(child, "id", 8L);
    child.setGuardianUserId(99L);
    when(users.findByEmail(EMAIL)).thenReturn(Optional.of(userWithId(7L)));
    when(users.findById(8L)).thenReturn(Optional.of(child));

    assertThatThrownBy(() -> service().list(EMAIL, 8L, null))
        .isInstanceOf(ResponseStatusException.class)
        .extracting(e -> ((ResponseStatusException) e).getStatusCode())
        .isEqualTo(HttpStatus.FORBIDDEN);
  }

  private static byte[] bytes(String value) {
    return value.getBytes(StandardCharsets.UTF_8);
  }
}
