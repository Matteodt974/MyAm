package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.config.JwtProperties;
import io.jsonwebtoken.ExpiredJwtException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;

@ExtendWith(MockitoExtension.class)
class JwtServiceTest {

  private static final String EMAIL = "user@test.com";
  private static final String SECRET = "01234567890123456789012345678901";

  @Mock private JwtProperties jwtProperties;
  @Mock private UserDetails userDetails;

  private JwtService service(long accessExpiration, long refreshExpiration) {
    when(jwtProperties.secret()).thenReturn(SECRET);
    when(jwtProperties.accessExpiration()).thenReturn(accessExpiration);
    lenient().when(jwtProperties.refreshExpiration()).thenReturn(refreshExpiration);
    return new JwtService(jwtProperties);
  }

  @Test
  void generateAccessToken_whenValidUser_returnsValidTokenWithEmailClaim() {
    when(userDetails.getUsername()).thenReturn(EMAIL);
    JwtService jwtService = service(3600000L, 86400000L);

    String token = jwtService.generateAccessToken(userDetails, 1L);

    assertThat(token).isNotEmpty();
    assertThat(jwtService.extractEmail(token)).isEqualTo(EMAIL);
    assertThat(jwtService.isTokenValid(token, userDetails)).isTrue();
  }

  @Test
  void isTokenValid_whenEmailDoesNotMatchUserDetails_returnsFalse() {
    when(userDetails.getUsername()).thenReturn(EMAIL);
    JwtService jwtService = service(3600000L, 86400000L);
    String token = jwtService.generateAccessToken(userDetails, 1L);

    when(userDetails.getUsername()).thenReturn("other@test.com");

    assertThat(jwtService.isTokenValid(token, userDetails)).isFalse();
  }

  @Test
  void isTokenValid_whenTokenExpired_throwsExpiredJwtException() {
    when(userDetails.getUsername()).thenReturn(EMAIL);
    JwtService jwtService = service(-1000L, 86400000L);
    String token = jwtService.generateAccessToken(userDetails, 1L);

    assertThatThrownBy(() -> jwtService.isTokenValid(token, userDetails))
        .isInstanceOf(ExpiredJwtException.class);
  }

  @Test
  void getExpirations_returnsPropertiesValues() {
    JwtService jwtService = service(3600000L, 86400000L);

    assertThat(jwtService.getAccessExpirationMs()).isEqualTo(3600000L);
    assertThat(jwtService.getRefreshExpirationMs()).isEqualTo(86400000L);
  }
}
