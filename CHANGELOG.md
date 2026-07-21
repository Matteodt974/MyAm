# Changelog

## [Unreleased] — JWT Authentication

### Backend

- **Ajout** endpoints `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout` avec JWT (access 15 min, refresh 7 jours).
- **Ajout** `JwtService`, `RefreshTokenService` (SHA-256 hash, rotation, révocation), `AuthService`, `UserDetailsServiceImpl`.
- **Ajout** `JwtAuthFilter`, `CustomAuthEntryPoint`, `CustomAccessDeniedHandler`, `GlobalExceptionHandler`.
- **Ajout** `SecurityConfig` : `BCrypt`, `ADD` stateless, CORS restreint à `localhost` + `10.0.2.2`.
- **Ajout** `JwtProperties`, étend `AppProperties` avec `encryptionMasterKey`.
- **Ajout** entité `User` avec `AccountType` (STANDALONE/MANAGED) et `UserRepository`.
- **Ajout** entités et repositories : `DigestiveJournalEntry`, `ProfileShare`, `ScanHistory`.
- **Ajout** `EncryptionService` pour le chiffrement AES des données sensibles.
- **Sécurité** seuls les comptes `STANDALONE` s'authentifient ; `MANAGED` exclus.
- **Routes publiques** : `/auth/**`, `/health`, `/docs/**`, `/v1/scan/**`, `/v1/label/**`.
- **Correction** `EncryptionService` : découplé du JWT secret, utilise désormais `ENCRYPTION_MASTER_KEY`.
- **Correction** `JwtAuthFilter` placé avant `AnonymousAuthenticationFilter` pour que le JWT ne soit pas ignoré.
- **Correction** `JwtService.isTokenValid` compare le claim `email` au lieu du `subject` (userId).
- **Correction** validation errors retournent `400 Bad Request` au lieu de `401`.
- **Ajout** config H2 pour les tests, `DishAnalysisServiceTest` mis à jour.

### Frontend

- **Ajout** écrans login / register avec validation.
- **Ajout** `AuthRepository` (API calls + secure token storage via `flutter_secure_storage`).
- **Ajout** `AuthInterceptor` avec verrou global pour éviter les refresh concurrents.
- **Ajout** `AuthStateProvider` (Riverpod `AsyncNotifier`).
- **Ajout** redirections de route GoRouter selon l'état d'authentification.
- **Ajout** bouton déconnexion et section compte dans l'écran profil.
- **Correction** SnackBar de succès après inscription affiché sur l'écran de connexion.

### CI / Outils

- **Ajout** `.fvmrc` pour épingler Flutter 3.44.0.
- **Ajout** service PostgreSQL 16 et variables d'environnement dans le workflow CI.

### ⚠️ Bugs / Limites connues

- **Flash login au démarrage** : si l'utilisateur est déjà connecté, l'écran de login apparaît 1-2 frames avant la redirection vers `/`. L'`authStateProvider` est en `loading` et le routeur le traite comme "non authentifié".
- **Parsing d'erreurs fragile** : `AuthController._formatError()` fait du string matching sur `error.toString()`. Si Dio change son format ou si le backend modifie ses messages, les erreurs deviendront génériques.
- **Pas de retry réseau** : si le serveur est temporairement indisponible, l'utilisateur doit cliquer manuellement à nouveau.

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
