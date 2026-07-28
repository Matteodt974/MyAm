package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.DigestiveEntryRequest;
import com.uqam.inm5151.scan.dto.DigestiveEntryResponse;
import com.uqam.inm5151.scan.repository.DigestiveJournalEntryRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Service metier UC-23 : journal digestif (echelle de Bristol).
 *
 * <p>Donnees de sante sensibles (Loi 25 / RGPD) : le type Bristol et les notes sont chiffres au
 * repos via {@link EncryptionService} et ne sont dechiffres que pour le proprietaire authentifie.
 */
@Service
public class DigestiveJournalService {

  private final DigestiveJournalEntryRepository repository;
  private final EncryptionService encryption;
  private final UserRepository users;

  public DigestiveJournalService(
      DigestiveJournalEntryRepository repository,
      EncryptionService encryption,
      UserRepository users) {
    this.repository = repository;
    this.encryption = encryption;
    this.users = users;
  }

  public DigestiveEntryResponse create(String email, DigestiveEntryRequest request) {
    Long userId = resolveUserId(email);
    byte[] bristolEncrypted = encryption.encrypt(String.valueOf(request.bristolType()));
    String notes =
        request.notes() == null || request.notes().isBlank() ? null : request.notes().trim();
    byte[] notesEncrypted = notes == null ? null : encryption.encrypt(notes);

    DigestiveJournalEntry saved =
        repository.save(
            new DigestiveJournalEntry(
                userId, request.occurredAt(), bristolEncrypted, notesEncrypted));
    return toResponse(saved);
  }

  public List<DigestiveEntryResponse> list(String email, Instant since) {
    Long userId = resolveUserId(email);
    List<DigestiveJournalEntry> entries =
        since == null
            ? repository.findTop1000ByUserIdOrderByOccurredAtDesc(userId)
            : repository.findByUserIdAndOccurredAtAfterOrderByOccurredAtDesc(userId, since);
    return entries.stream().map(this::toResponse).toList();
  }

  private Long resolveUserId(String email) {
    return users
        .findByEmail(email)
        .map(User::getId)
        .orElseThrow(
            () -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non trouvé"));
  }

  private DigestiveEntryResponse toResponse(DigestiveJournalEntry entry) {
    int bristolType = Integer.parseInt(encryption.decrypt(entry.getBristolTypeEncrypted()));
    String notes =
        entry.getNotesEncrypted() == null ? null : encryption.decrypt(entry.getNotesEncrypted());
    return new DigestiveEntryResponse(
        entry.getId(), entry.getOccurredAt(), bristolType, notes, entry.getCreatedAt());
  }
}
