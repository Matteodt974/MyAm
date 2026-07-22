package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.config.JwtProperties;
import com.uqam.inm5151.scan.domain.RefreshToken;
import com.uqam.inm5151.scan.repository.RefreshTokenRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import jakarta.transaction.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.NoSuchElementException;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class RefreshTokenService {
  private final RefreshTokenRepository refreshTokenRepository;
  private final UserRepository userRepository;
  private final JwtProperties jwtProperties;

  public RefreshTokenService(
      RefreshTokenRepository refreshTokenRepository,
      UserRepository userRepository,
      JwtProperties jwtProperties) {
    this.refreshTokenRepository = refreshTokenRepository;
    this.userRepository = userRepository;
    this.jwtProperties = jwtProperties;
  }

  /** Crée un refresh token opaque et retourne sa valeur brute (à transmettre au client). */
  public String createRefreshToken(Long userId) {
    if (!userRepository.existsById(userId)) {
      throw new NoSuchElementException("Utilisateur non trouvé");
    }
    String rawToken = UUID.randomUUID().toString();
    Instant now = Instant.now();
    RefreshToken token =
        new RefreshToken(
            userId, hashToken(rawToken), now, now.plusMillis(jwtProperties.refreshExpiration()));
    refreshTokenRepository.save(token);
    return rawToken;
  }

  /**
   * Rotaion d'un refresh token : l'ancien est révoqué et un nouveau est émis. Retourne la valeur
   * brute du nouveau token.
   */
  @Transactional
  public String rotate(String rawToken) {
    RefreshToken oldToken = verify(rawToken);
    oldToken.revoke();
    refreshTokenRepository.save(oldToken);
    return createRefreshToken(oldToken.getUserId());
  }

  public RefreshToken verify(String rawToken) {
    RefreshToken token =
        refreshTokenRepository
            .findByTokenHash(hashToken(rawToken))
            .orElseThrow(() -> new IllegalArgumentException("Refresh token invalide"));

    if (token.getRevokedAt() != null) {
      throw new IllegalArgumentException("Refresh token révoqué");
    }
    if (token.getExpiresAt().isBefore(Instant.now())) {
      throw new IllegalArgumentException("Refresh token expiré");
    }
    return token;
  }

  @Transactional
  public void revoke(String rawToken) {
    RefreshToken token = verify(rawToken);
    token.revoke();
    refreshTokenRepository.save(token);
  }

  private String hashToken(String rawToken) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
      StringBuilder hexString = new StringBuilder();
      for (byte b : hash) {
        hexString.append(String.format("%02x", b));
      }
      return hexString.toString();
    } catch (Exception e) {
      throw new IllegalStateException("Échec du hachage du refresh token", e);
    }
  }
}
