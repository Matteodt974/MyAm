package com.uqam.inm5151.scan.service;

import com.uqam.inm5151.scan.domain.AccountType;
import com.uqam.inm5151.scan.domain.User;
import com.uqam.inm5151.scan.dto.AuthResponse;
import com.uqam.inm5151.scan.dto.LoginRequest;
import com.uqam.inm5151.scan.dto.RefreshRequest;
import com.uqam.inm5151.scan.dto.RegisterRequest;
import com.uqam.inm5151.scan.dto.UserDto;
import com.uqam.inm5151.scan.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
  private static final String PASSWORD_PATTERN =
      "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$";

  private final UserRepository userRepository;
  private final RefreshTokenService refreshTokenService;
  private final JwtService jwtService;
  private final PasswordEncoder passwordEncoder;
  private final AuthenticationManager authenticationManager;
  private final UserDetailsServiceImpl userDetailsService;

  public AuthService(
      UserRepository userRepository,
      RefreshTokenService refreshTokenService,
      JwtService jwtService,
      PasswordEncoder passwordEncoder,
      AuthenticationManager authenticationManager,
      UserDetailsServiceImpl userDetailsService) {
    this.userRepository = userRepository;
    this.refreshTokenService = refreshTokenService;
    this.jwtService = jwtService;
    this.passwordEncoder = passwordEncoder;
    this.authenticationManager = authenticationManager;
    this.userDetailsService = userDetailsService;
  }

  public AuthResponse register(RegisterRequest request) {
    if (userRepository.existsByEmail(request.email())) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "Cet email est déjà utilisé");
    }
    validatePassword(request.password());

    User user = new User(request.displayName(), AccountType.STANDALONE);
    user.setEmail(request.email());
    user.setPasswordHash(passwordEncoder.encode(request.password()));
    userRepository.save(user);

    return buildAuthResponse(user);
  }

  public AuthResponse login(LoginRequest request) {
    authenticationManager.authenticate(
        new UsernamePasswordAuthenticationToken(request.email(), request.password()));

    User user =
        userRepository
            .findByEmail(request.email())
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non trouvé"));

    if (user.getAccountType() != AccountType.STANDALONE) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "Les comptes gérés ne peuvent pas se connecter directement");
    }

    return buildAuthResponse(user);
  }

  public AuthResponse refresh(RefreshRequest request) {
    var token = refreshTokenService.verify(request.refreshToken());
    User user =
        userRepository
            .findById(token.getUserId())
            .orElseThrow(
                () -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non trouvé"));

    String newRefreshToken = refreshTokenService.rotate(request.refreshToken());
    return buildAuthResponse(user, newRefreshToken);
  }

  public void logout(RefreshRequest request) {
    refreshTokenService.revoke(request.refreshToken());
  }

  private AuthResponse buildAuthResponse(User user) {
    String refreshToken = refreshTokenService.createRefreshToken(user.getId());
    return buildAuthResponse(user, refreshToken);
  }

  private AuthResponse buildAuthResponse(User user, String refreshToken) {
    UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
    String accessToken = jwtService.generateAccessToken(userDetails, user.getId());
    long accessExpiresIn = jwtService.getAccessExpirationMs() / 1000;
    long refreshExpiresIn = jwtService.getRefreshExpirationMs() / 1000;

    return new AuthResponse(
        accessToken,
        refreshToken,
        "Bearer",
        accessExpiresIn,
        refreshExpiresIn,
        new UserDto(user.getId(), user.getEmail(), user.getDisplayName()));
  }

  private void validatePassword(String password) {
    if (!password.matches(PASSWORD_PATTERN)) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST,
          "Mot de passe invalide : minimum 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre");
    }
  }
}
