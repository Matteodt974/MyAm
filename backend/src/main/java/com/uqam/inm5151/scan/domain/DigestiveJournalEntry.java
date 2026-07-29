package com.uqam.inm5151.scan.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(
    name = "digestive_journal_entries",
    indexes =
        @Index(
            name = "idx_digestive_journal_user_profile_time",
            columnList = "user_id, profile_id, occurred_at"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class DigestiveJournalEntry {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id", nullable = false)
  private Long userId;

  /** Profil concerne. Null uniquement pour les anciennes entrees, qui appartiennent au parent. */
  @Column(name = "profile_id")
  private Long profileId;

  @Column(name = "occurred_at", nullable = false)
  private Instant occurredAt;

  @Column(name = "bristol_type_encrypted", nullable = false)
  private byte[] bristolTypeEncrypted;

  @Column(name = "notes_encrypted")
  private byte[] notesEncrypted;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public DigestiveJournalEntry(
      Long userId,
      Long profileId,
      Instant occurredAt,
      byte[] bristolTypeEncrypted,
      byte[] notesEncrypted) {
    this.userId = userId;
    this.profileId = profileId;
    this.occurredAt = occurredAt;
    this.bristolTypeEncrypted = bristolTypeEncrypted;
    this.notesEncrypted = notesEncrypted;
    this.createdAt = Instant.now();
  }

  /** Compatibility constructor for legacy tests and migrations: profile = owner. */
  public DigestiveJournalEntry(
      Long userId, Instant occurredAt, byte[] bristolTypeEncrypted, byte[] notesEncrypted) {
    this(userId, userId, occurredAt, bristolTypeEncrypted, notesEncrypted);
  }
}
