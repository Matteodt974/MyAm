package com.uqam.inm5151.scan.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.List;

/** UC-28 : profil enfant restreint, tel qu'importe par le beneficiaire du code QR. */
public record SharedProfileResponse(
    @JsonProperty("display_name") String displayName,
    List<String> allergies,
    List<String> diets,
    @JsonProperty("expires_at") Instant expiresAt) {}
