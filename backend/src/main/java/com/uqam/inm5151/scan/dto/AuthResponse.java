package com.uqam.inm5151.scan.dto;

public record AuthResponse(
    String accessToken,
    String refreshToken,
    String tokenType,
    long accessExpiresIn,
    long refreshExpiresIn,
    UserDto user) {}
