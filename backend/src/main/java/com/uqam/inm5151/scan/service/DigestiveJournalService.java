package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.DigestiveJournalEntry;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.DigestiveEntryRequest;
import com.uqam.inm5151.scan.dto.DigestiveEntryResponse;
import com.uqam.inm5151.scan.repository.DigestiveJournalEntryRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
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

  public DigestiveEntryResponse create(
      String email, Long profileId, DigestiveEntryRequest request) {
    User owner = requireAccessibleProfile(email, profileId);
    byte[] bristolEncrypted = encryption.encrypt(String.valueOf(request.bristolType()));
    String notes =
        request.notes() == null || request.notes().isBlank() ? null : request.notes().trim();
    byte[] notesEncrypted = notes == null ? null : encryption.encrypt(notes);

    DigestiveJournalEntry saved =
        repository.save(
            new DigestiveJournalEntry(
                owner.getId(), profileId, request.occurredAt(), bristolEncrypted, notesEncrypted));
    return toResponse(saved);
  }

  public List<DigestiveEntryResponse> list(String email, Long profileId, Instant since) {
    User owner = requireAccessibleProfile(email, profileId);
    List<DigestiveJournalEntry> entries =
        since == null
            ? repository.findForProfile(owner.getId(), profileId)
            : repository.findForProfileSince(owner.getId(), profileId, since);
    return entries.stream().map(this::toResponse).toList();
  }

  private User requireAccessibleProfile(String email, Long profileId) {
    User owner =
        users
            .findByEmail(email)
            .orElseThrow(
                () ->
                    new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non trouvé"));
    if (owner.getId().equals(profileId)) {
      return owner;
    }
    User profile =
        users
            .findById(profileId)
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profil introuvable"));
    if (!Objects.equals(profile.getGuardianUserId(), owner.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Profil non accessible");
    }
    return owner;
  }

  private DigestiveEntryResponse toResponse(DigestiveJournalEntry entry) {
    int bristolType = Integer.parseInt(encryption.decrypt(entry.getBristolTypeEncrypted()));
    String notes =
        entry.getNotesEncrypted() == null ? null : encryption.decrypt(entry.getNotesEncrypted());
    return new DigestiveEntryResponse(
        entry.getId(), entry.getOccurredAt(), bristolType, notes, entry.getCreatedAt());
  }
}
