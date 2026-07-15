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

/** Jeton de rafraichissement JWT (UC-13b), stocke hache pour permettre revocation/logout. */
@Entity
@Table(
    name = "refresh_tokens",
    indexes = @Index(name = "idx_refresh_tokens_user", columnList = "user_id"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RefreshToken {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id", nullable = false)
  private Long userId;

  @Column(name = "token_hash", nullable = false, unique = true)
  private String tokenHash;

  @Column(name = "issued_at", nullable = false)
  private Instant issuedAt;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "revoked_at")
  private Instant revokedAt;

  public RefreshToken(Long userId, String tokenHash, Instant issuedAt, Instant expiresAt) {
    this.userId = userId;
    this.tokenHash = tokenHash;
    this.issuedAt = issuedAt;
    this.expiresAt = expiresAt;
  }

  public void revoke() {
    this.revokedAt = Instant.now();
  }
}
