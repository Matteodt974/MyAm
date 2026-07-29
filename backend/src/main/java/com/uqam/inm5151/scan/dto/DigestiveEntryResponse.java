package com.uqam.inm5151.scan.dto;

import java.time.Instant;

/** UC-23 : entree du journal digestif renvoyee dechiffree au proprietaire authentifie. */
public record DigestiveEntryResponse(
    Long id, Instant occurredAt, int bristolType, String notes, Instant createdAt) {}
