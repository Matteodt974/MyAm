package com.uqam.inm5151.scan.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "jwt")
public record JwtProperties(String secret, Long accessExpiration, Long refreshExpiration) {

  public JwtProperties {
    if (secret == null || secret.isBlank()) {
      throw new IllegalStateException("jwt.secret doit être configuré (variable JWT_SECRET)");
    }
    if (secret.length() < 32) {
      throw new IllegalStateException(
          "jwt.secret doit faire au moins 32 caractères pour HMAC-SHA256");
    }
    if (accessExpiration == null || accessExpiration <= 0) {
      throw new IllegalStateException("jwt.access-expiration doit être positif");
    }
    if (refreshExpiration == null || refreshExpiration <= 0) {
      throw new IllegalStateException("jwt.refresh-expiration doit être positif");
    }
  }
}
