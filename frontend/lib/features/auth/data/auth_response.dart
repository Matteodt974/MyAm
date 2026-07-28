class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int accessExpiresIn;
  final int refreshExpiresIn;
  final UserDto user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      accessExpiresIn: (json['accessExpiresIn'] as num).toInt(),
      refreshExpiresIn: (json['refreshExpiresIn'] as num).toInt(),
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'accessExpiresIn': accessExpiresIn,
      'refreshExpiresIn': refreshExpiresIn,
      'user': user.toJson(),
    };
  }
}

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final int id;
  final String email;
  final String displayName;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'displayName': displayName};
  }
}
