# Changelog

## [Unreleased]

### Ajouté

- **Authentification JWT complète** — endpoints `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`
  - Tokens access (15 min) + refresh (7 jours) avec rotation et révocation
  - Hash SHA-256 des refresh tokens en base
  - Seuls les comptes STANDALONE s'authentifient ; les MANAGED sont exclus
- **Écrans login et register** avec validation des champs
  - Bascule de visibilité du mot de passe
  - Message de succès après inscription redirigeant vers login
- **Gestion persistante de l'authentification** côté client
  - Stockage sécurisé des tokens (flutter_secure_storage)
  - Intercepteur Dio avec verrou global anti-conflits de refresh
  - Redirection GoRouter dynamique selon l'état connecté
- **Chiffrement AES** des données sensibles du journal digestif (EncryptionService)
- **Entités et repositories** : User (STANDALONE/MANAGED), DigestiveJournalEntry, ProfileShare, ScanHistory
- **Tests d'authentification** (repository, controller, widgets)
- **Scan Trivy** des vulnérabilités HIGH/CRITICAL dans le CI
- **Service PostgreSQL 16** dans le CI pour les tests d'intégration
- **Fichier .fvmrc** pour épingler Flutter 3.44.0

### Modifié

- Architecture backend migrée vers JWT (SecurityConfig, JwtAuthFilter, CORS)
- Routes publiques : /auth/**, /health, /docs/**, /v1/**
- Variables d'environnement CI déplacées dans DynamicPropertySource (plus de secrets en dur)
- Permissions du CI restreintes à contents: read
- .env.example mis à jour avec les nouvelles variables

### Corrigé

- SnackBar de succès après inscription désormais visible sur l'écran de connexion
- Recréation intempestive du GoRouter lors des changements d'état auth
- Validation errors retournent 400 Bad Request au lieu de 401
- EncryptionService découplé du JWT secret, utilise ENCRYPTION_MASTER_KEY
- JwtAuthFilter placé avant AnonymousAuthenticationFilter
- Comparaison du claim email au lieu de subject dans isTokenValid
- Format jdbc:... requis pour DATABASE_URL dans Spring Boot

### Sécurité

- Seuls les comptes STANDALONE peuvent s'authentifier
- Refresh tokens révocables avec rotation automatique
- CI en read-only, plus aucun secret en dur dans les fichiers YAML

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
