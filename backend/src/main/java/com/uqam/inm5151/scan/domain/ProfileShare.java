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
import lombok.Setter;

@Entity
@Table(
    name = "profile_shares",
    indexes = @Index(name = "idx_profile_shares_owner", columnList = "owner_user_id"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProfileShare {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "owner_user_id", nullable = false)
  private Long ownerUserId;

  @Column(name = "created_by_user_id", nullable = false)
  private Long createdByUserId;

  @Column(name = "share_token", nullable = false, unique = true)
  private String shareToken;

  private String label;

  @Setter
  @Column(name = "expires_at")
  private Instant expiresAt;

  @Column(name = "revoked_at")
  private Instant revokedAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public ProfileShare(Long ownerUserId, Long createdByUserId, String shareToken, String label) {
    this.ownerUserId = ownerUserId;
    this.createdByUserId = createdByUserId;
    this.shareToken = shareToken;
    this.label = label;
    this.createdAt = Instant.now();
  }

  public void revoke() {
    this.revokedAt = Instant.now();
  }
}
