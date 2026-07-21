# Changelog

## [Unreleased] — JWT Authentication

### Backend

- **Add** endpoints `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout` avec JWT (access 15 min, refresh 7 jours).
- **Add** `JwtService`, `RefreshTokenService` (SHA-256 hash, rotation, révocation), `AuthService`, `UserDetailsServiceImpl`.
- **Add** `JwtAuthFilter`, `CustomAuthEntryPoint`, `CustomAccessDeniedHandler`, `GlobalExceptionHandler`.
- **Add** `SecurityConfig` : `BCrypt`, `ADD` stateless, CORS restreint à `localhost` + `10.0.2.2`.
- **Add** `JwtProperties`, étend `AppProperties` avec `encryptionMasterKey`.
- **Security** seuls les comptes `STANDALONE` s'authentifient ; `MANAGED` exclus.
- **Routes publiques** : `/auth/**`, `/health`, `/docs/**`, `/v1/scan/**`, `/v1/label/**`.
- **Fix** `EncryptionService` : découplé du JWT secret, utilise désormais `ENCRYPTION_MASTER_KEY`.
- **Fix** `JwtAuthFilter` placé avant `AnonymousAuthenticationFilter` pour que le JWT ne soit pas ignoré.
- **Fix** `JwtService.isTokenValid` compare le claim `email` au lieu du `subject` (userId).
- **Fix** validation errors retournent `400 Bad Request` au lieu de `401`.
- **Add** H2 test config, `DishAnalysisServiceTest` à jour.

### Frontend

- **Add** écrans login / register avec validation.
- **Add** `AuthRepository` (API calls + secure token storage via `flutter_secure_storage`).
- **Add** `AuthInterceptor` avec verrou global pour éviter les refresh concurrents.
- **Add** `AuthStateProvider` (Riverpod `AsyncNotifier`).
- **Add** redirections de route GoRouter selon l'état d'authentification.
- **Add** bouton déconnexion et section compte dans l'écran profil.

## [Previous] — Fixes lancement local & .env.example

### Backend

- **Fix** `DATABASE_URL` : format `jdbc:postgresql://...` requis par Spring Boot. Le format
  `postgresql://` sans préfixe `jdbc:` provoque
  `IllegalArgumentException: URL must start with 'jdbc'`.
- **Fix** `JWT_SECRET` : valeur vide causait
  `IllegalStateException: jwt.secret doit être configuré`. Défini
  `change-me-for-local-dev-0123456789abcdef` pour le développement local.
- **Docs** `.env.example` : ajout de `OCR_URL`, `TRANSLATE_URL`, `DEEPL_API_KEY`,
  `LOGMEAL_API_KEY` et commentaires Docker vs local.

### Frontend

- **Fix** `build_runner` : régénération de `label_result.freezed.dart` après ajout des
  champs `riskLevel` et `matchedAllergens` dans `LabelResult`. L'app ne compilait pas
  car le fichier généré par Freezed était obsolète.
