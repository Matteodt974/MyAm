package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.config.JwtProperties;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Service;

/**
 * Chiffrement AES/GCM
 *
 * @see <a
 *     href="https://docs.oracle.com/en/java/javase/17/security/java-cryptography-architecture-jca-reference-guide.html">Guide
 *     JCA</a>
 */
@Service
public class EncryptionService {
  private static final int GCM_TAG_BITS = 128;
  private static final int IV_BYTES = 12;

  private final SecretKeySpec key;
  private final SecureRandom random = new SecureRandom();

  public EncryptionService(JwtProperties properties) {
    this.key = new SecretKeySpec(sha256(properties.secret()), "AES");
  }

  public byte[] encrypt(String plaintext) {
    try {
      byte[] iv = new byte[IV_BYTES];
      random.nextBytes(iv);
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_BITS, iv));
      byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
      byte[] result = new byte[iv.length + ciphertext.length];
      System.arraycopy(iv, 0, result, 0, iv.length);
      System.arraycopy(ciphertext, 0, result, iv.length, ciphertext.length);
      return result;
    } catch (Exception e) {
      throw new IllegalStateException("Échec du chiffrement", e);
    }
  }

  public String decrypt(byte[] payload) {
    try {
      byte[] iv = Arrays.copyOfRange(payload, 0, IV_BYTES);
      byte[] ciphertext = Arrays.copyOfRange(payload, IV_BYTES, payload.length);
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_BITS, iv));
      return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
    } catch (Exception e) {
      throw new IllegalStateException("Échec du déchiffrement", e);
    }
  }

  private static byte[] sha256(String value) {
    try {
      return MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException(e);
    }
  }
}
