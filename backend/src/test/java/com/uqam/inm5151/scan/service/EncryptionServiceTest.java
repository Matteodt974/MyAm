package com.uqam.inm5151.scan.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.uqam.inm5151.scan.config.AppProperties;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class EncryptionServiceTest {

  @Mock private AppProperties appProperties;

  private EncryptionService service() {
    when(appProperties.encryptionMasterKey()).thenReturn("secret key");
    return new EncryptionService(appProperties);
  }

  @Test
  void encryptAndDecrypt_whenValidText_returnsOriginalText() {
    String plaintext = "Sensitive data";

    byte[] ciphertext = service().encrypt(plaintext);
    String decrypted = service().decrypt(ciphertext);

    assertThat(ciphertext).isNotEqualTo(plaintext.getBytes(StandardCharsets.UTF_8));
    assertThat(decrypted).isEqualTo(plaintext);
  }

  @Test
  void encrypt_whenCalledTwiceWithSameText_producesDifferentCiphertexts() {
    String plaintext = "Same sensitive data";
    EncryptionService encryptionService = service();

    byte[] first = encryptionService.encrypt(plaintext);
    byte[] second = encryptionService.encrypt(plaintext);

    assertThat(first).isNotEqualTo(second);
  }

  @Test
  void decrypt_whenPayloadIsCorrupted_throwsIllegalStateException() {
    byte[] invalidPayload = new byte[] {1, 2, 3, 4, 5};

    assertThatThrownBy(() -> service().decrypt(invalidPayload))
        .isInstanceOf(IllegalStateException.class);
  }
}
