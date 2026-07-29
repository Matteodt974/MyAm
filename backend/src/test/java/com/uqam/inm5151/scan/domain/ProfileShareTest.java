package com.uqam.inm5151.scan.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class ProfileShareTest {

  private static final Instant NOW = Instant.parse("2026-07-28T12:00:00Z");

  private ProfileShare share(Instant expiresAt) {
    return new ProfileShare(2L, 1L, "hash", "Alice", new byte[] {1}, expiresAt);
  }

  @Test
  void shareWithoutExpiryStaysActive() {
    assertThat(share(null).isActive(NOW)).isTrue();
  }

  @Test
  void shareStaysActiveBeforeExpiry() {
    assertThat(share(NOW.plusSeconds(60)).isActive(NOW)).isTrue();
  }

  @Test
  void expiredShareIsNotActive() {
    assertThat(share(NOW.minusSeconds(1)).isActive(NOW)).isFalse();
  }

  @Test
  void revokedShareIsNotActiveEvenWithoutExpiry() {
    ProfileShare share = share(null);
    share.revoke();

    assertThat(share.isActive(NOW)).isFalse();
    assertThat(share.getRevokedAt()).isNotNull();
  }
}
