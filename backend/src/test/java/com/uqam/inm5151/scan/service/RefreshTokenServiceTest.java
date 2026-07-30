package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.config.JwtProperties;
import com.uqam.inm5151.scan.domain.RefreshToken;
import com.uqam.inm5151.scan.repository.RefreshTokenRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.NoSuchElementException;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

  private static final Long USER_ID = 42L;
  private static final String RAW_TOKEN = "test-raw-token";
  private static final long EXPIRE_MS = 86400000L;

  @Mock private RefreshTokenRepository refreshTokenRepository;
  @Mock private UserRepository userRepository;
  @Mock private JwtProperties jwtProperties;

  private RefreshTokenService service() {
    return new RefreshTokenService(refreshTokenRepository, userRepository, jwtProperties);
  }

  private String hash(String raw) throws Exception {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    byte[] hash = digest.digest(raw.getBytes(StandardCharsets.UTF_8));
    StringBuilder hexString = new StringBuilder();
    for (byte b : hash) {
      hexString.append(String.format("%02x", b));
    }
    return hexString.toString();
  }

  @Test
  void createRefreshToken_whenUserExists_savesAndReturnsRawToken() {
    when(userRepository.existsById(USER_ID)).thenReturn(true);
    when(jwtProperties.refreshExpiration()).thenReturn(EXPIRE_MS);
    when(refreshTokenRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    String rawToken = service().createRefreshToken(USER_ID);

    assertThat(rawToken).isNotBlank();
    verify(refreshTokenRepository).save(any(RefreshToken.class));
  }

  @Test
  void createRefreshToken_whenUserNotFound_throwsNoSuchElementException() {
    when(userRepository.existsById(USER_ID)).thenReturn(false);

    assertThatThrownBy(() -> service().createRefreshToken(USER_ID))
        .isInstanceOf(NoSuchElementException.class);
  }

  @Test
  void verify_whenTokenValid_returnsToken() throws Exception {
    RefreshToken storedToken =
        new RefreshToken(USER_ID, hash(RAW_TOKEN), Instant.now(), Instant.now().plusSeconds(3600));
    when(refreshTokenRepository.findByTokenHash(hash(RAW_TOKEN)))
        .thenReturn(Optional.of(storedToken));

    RefreshToken result = service().verify(RAW_TOKEN);

    assertThat(result).isEqualTo(storedToken);
  }

  @Test
  void verify_whenTokenNotFound_throwsIllegalArgumentException() throws Exception {
    when(refreshTokenRepository.findByTokenHash(hash(RAW_TOKEN))).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service().verify(RAW_TOKEN))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("invalide");
  }

  @Test
  void verify_whenTokenRevoked_throwsIllegalArgumentException() throws Exception {
    RefreshToken storedToken =
        new RefreshToken(USER_ID, hash(RAW_TOKEN), Instant.now(), Instant.now().plusSeconds(3600));
    storedToken.revoke();
    when(refreshTokenRepository.findByTokenHash(hash(RAW_TOKEN)))
        .thenReturn(Optional.of(storedToken));

    assertThatThrownBy(() -> service().verify(RAW_TOKEN))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("révoqué");
  }

  @Test
  void verify_whenTokenExpired_throwsIllegalArgumentException() throws Exception {
    RefreshToken storedToken =
        new RefreshToken(
            USER_ID,
            hash(RAW_TOKEN),
            Instant.now().minusSeconds(7200),
            Instant.now().minusSeconds(3600));
    when(refreshTokenRepository.findByTokenHash(hash(RAW_TOKEN)))
        .thenReturn(Optional.of(storedToken));

    assertThatThrownBy(() -> service().verify(RAW_TOKEN))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("expiré");
  }

  @Test
  void rotate_whenValidToken_revokesOldAndReturnsNewToken() throws Exception {
    RefreshToken oldToken =
        new RefreshToken(USER_ID, hash(RAW_TOKEN), Instant.now(), Instant.now().plusSeconds(3600));
    when(refreshTokenRepository.findByTokenHash(hash(RAW_TOKEN))).thenReturn(Optional.of(oldToken));
    when(userRepository.existsById(USER_ID)).thenReturn(true);
    when(jwtProperties.refreshExpiration()).thenReturn(EXPIRE_MS);
    when(refreshTokenRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    String newRawToken = service().rotate(RAW_TOKEN);

    assertThat(newRawToken).isNotBlank().isNotEqualTo(RAW_TOKEN);
    assertThat(oldToken.getRevokedAt()).isNotNull();
    verify(refreshTokenRepository, org.mockito.Mockito.times(2)).save(any(RefreshToken.class));
  }

  @Test
  void revoke_whenValidToken_setsRevokedAtAndSaves() throws Exception {
    RefreshToken storedToken =
        new RefreshToken(USER_ID, hash(RAW_TOKEN), Instant.now(), Instant.now().plusSeconds(3600));
    when(refreshTokenRepository.findByTokenHash(hash(RAW_TOKEN)))
        .thenReturn(Optional.of(storedToken));

    service().revoke(RAW_TOKEN);

    assertThat(storedToken.getRevokedAt()).isNotNull();
    verify(refreshTokenRepository).save(storedToken);
  }
}
