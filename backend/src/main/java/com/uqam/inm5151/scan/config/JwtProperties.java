package com.uqam.inm5151.scan.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "jwt")
public record JwtProperties(String secret) {

  public JwtProperties {
    if (secret == null || secret.isBlank()) {
      throw new IllegalStateException("jwt.secret doit être configuré (variable JWT_SECRET)");
    }
  }
}
