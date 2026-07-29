package com.uqam.inm5151.scan.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.ProfileShare;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.ProfileShareRequest;
import com.uqam.inm5151.scan.dto.ProfileShareResponse;
import com.uqam.inm5151.scan.dto.SharedProfileResponse;
import com.uqam.inm5151.scan.repository.ProfileShareRepository;
import com.uqam.inm5151.scan.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * UC-28 : partage d'un profil enfant par code QR.
 *
 * <p>Le code QR ne transporte qu'un jeton opaque. L'instantane du profil (nom, allergies, regimes)
 * est conserve chiffre cote serveur, ce qui permet au parent de revoquer un partage deja distribue
 * et evite qu'une photo du code QR reste exploitable indefiniment.
 */
@Service
public class ProfileShareService {

  private final ProfileShareRepository shares;
  private final UserRepository users;
  private final EncryptionService encryption;
  private final CurrentUserService currentUser;
  private final ObjectMapper objectMapper = new ObjectMapper();

  public ProfileShareService(
      ProfileShareRepository shares,
      UserRepository users,
      EncryptionService encryption,
      CurrentUserService currentUser) {
    this.shares = shares;
    this.users = users;
    this.encryption = encryption;
    this.currentUser = currentUser;
  }

  @Transactional
  public ProfileShareResponse create(Long childId, ProfileShareRequest request) {
    User guardian = currentUser.getAuthenticatedUser();
    requireOwnedChild(guardian.getId(), childId);

    String rawToken = UUID.randomUUID().toString();
    Instant expiresAt =
        request.validityDays() == null
            ? null
            : Instant.now().plus(Duration.ofDays(request.validityDays()));

    shares.save(
        new ProfileShare(
            childId,
            guardian.getId(),
            hash(rawToken),
            request.displayName(),
            encryption.encrypt(serialize(request)),
            expiresAt));

    return new ProfileShareResponse(rawToken, expiresAt);
  }

  @Transactional(readOnly = true)
  public SharedProfileResponse redeem(String rawToken) {
    ProfileShare share =
        shares
            .findByShareToken(hash(rawToken))
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Code QR invalide"));

    if (!share.isActive(Instant.now())) {
      // 4b du UC : le beneficiaire doit redemander un code au parent.
      throw new ResponseStatusException(
          HttpStatus.GONE,
          "Ce code QR a expiré ou a été révoqué. Demandez-en un nouveau au parent.");
    }

    Map<String, Object> payload = deserialize(encryption.decrypt(share.getPayloadEncrypted()));

    return new SharedProfileResponse(
        String.valueOf(payload.getOrDefault("displayName", share.getLabel())),
        toStringList(payload.get("allergies")),
        toStringList(payload.get("diets")),
        share.getExpiresAt());
  }

  @Transactional
  public void revoke(Long childId, Long shareId) {
    User guardian = currentUser.getAuthenticatedUser();
    requireOwnedChild(guardian.getId(), childId);

    ProfileShare share =
        shares
            .findById(shareId)
            .filter(s -> childId.equals(s.getOwnerUserId()))
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Partage introuvable"));

    share.revoke();
    shares.save(share);
  }

  private void requireOwnedChild(Long guardianId, Long childId) {
    users
        .findById(childId)
        .filter(child -> child.getAccountType() == AccountType.MANAGED)
        .filter(child -> guardianId.equals(child.getGuardianUserId()))
        .orElseThrow(
            () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sous-profil introuvable"));
  }

  private String serialize(ProfileShareRequest request) {
    try {
      return objectMapper.writeValueAsString(
          Map.of(
              "displayName", request.displayName(),
              "allergies", request.allergies(),
              "diets", request.diets()));
    } catch (JsonProcessingException e) {
      throw new IllegalStateException("Échec de sérialisation du profil partagé", e);
    }
  }

  @SuppressWarnings("unchecked")
  private Map<String, Object> deserialize(String json) {
    try {
      return objectMapper.readValue(json, Map.class);
    } catch (JsonProcessingException e) {
      throw new IllegalStateException("Échec de lecture du profil partagé", e);
    }
  }

  private static List<String> toStringList(Object value) {
    if (value instanceof List<?> list) {
      return list.stream().map(String::valueOf).toList();
    }
    return List.of();
  }

  private static String hash(String rawToken) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      return HexFormat.of().formatHex(digest.digest(rawToken.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("SHA-256 indisponible", e);
    }
  }
}
