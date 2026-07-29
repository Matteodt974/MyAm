package com.uqam.inm5151.scan.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "scan")
public record AppProperties(
    String appName,
    String environment,
    String databaseUrl,
    String offBaseUrl,
    String obfBaseUrl,
    String offUserAgent,
    String geminiApiKey,
    String geminiModel,
    String fdcApiKey,
    String fdcBaseUrl,
    String encryptionMasterKey) {

  public AppProperties {
    if (encryptionMasterKey == null || encryptionMasterKey.isBlank()) {
      throw new IllegalStateException(
          "scan.encryption-master-key doit être configuré (variable ENCRYPTION_MASTER_KEY)");
    }
  }
}
