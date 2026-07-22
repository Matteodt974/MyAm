package com.uqam.inm5151.scan.dto;

public record TokenPair(String accessToken, String refreshToken, long accessExpiresIn) {}
