package com.uqam.inm5151.scan.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "scan")
public record AppProperties(
    String appName,
    String environment,
    String databaseUrl,
    String ocrUrl,
    String translateUrl,
    String offBaseUrl,
    String obfBaseUrl,
    String offUserAgent,
    String geminiApiKey,
    String geminiModel,
    String fdcApiKey,
    String fdcBaseUrl) {}
