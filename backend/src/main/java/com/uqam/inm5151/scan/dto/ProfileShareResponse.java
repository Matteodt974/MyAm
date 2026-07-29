package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;

/** UC-28 : jeton a encoder dans le code QR, remis une seule fois au parent. */
public record ProfileShareResponse(String token, @JsonProperty("expires_at") Instant expiresAt) {}
