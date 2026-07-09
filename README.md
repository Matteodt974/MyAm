# MyAm

Application mobile INM5151 pour scanner des produits alimentaires et cosmetiques.

- `backend/` : API Spring Boot.
- `frontend/` : application Flutter.

## Tech Stack

<p align="center">
  <!-- Frontend -->
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white"/>

  <!-- Backend -->
  <img src="https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white"/>
  <img src="https://img.shields.io/badge/springboot-%236DB33F.svg?style=for-the-badge&logo=springboot&logoColor=white"/>
  <img src="https://img.shields.io/badge/maven-C71A36?style=for-the-badge&logo=apachemaven&logoColor=white"/>

  <!-- DevOps -->
  <img src="https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white"/>
</p>

## Prerequis

- Flutter SDK 3.44.x stable + Android Studio (SDK, émulateur Android)
- Java 21
- Docker Desktop
- Xcode + CocoaPods (macOS, pour iOS)
- Python 3.x (`pre-commit`) + Node.js (`prettier`)

Verifier Flutter :

```bash
flutter doctor
```

## Installation

```bash
git clone git@github.com:Matteodt974/Allergies_mobile_app.git
cd Allergies_mobile_app
```

## Pre-commit (hooks de formatage automatique)

Le projet utilise [pre-commit](https://pre-commit.com/) pour formatter le code automatiquement a chaque commit :

- **Java** : Spotless (Google Java Format)
- **Dart** : `dart format`
- **YAML / JSON / Markdown** : Prettier

Installation :

```bash
pip install pre-commit
pre-commit install
```

Verifier que tout fonctionne :

```bash
pre-commit run --all-files
```

## Backend

```bash
cd backend
cp .env.example .env
./mvnw spring-boot:run
```

Avec Docker :

```bash
docker compose up --build
```

Swagger : http://localhost:8080/docs

Verification :

```bash
curl http://localhost:8080/health
```

## Frontend

```bash
cd frontend
flutter pub get
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

Sur telephone physique, remplacer `10.0.2.2` par l'adresse LAN de la machine qui lance le backend.

## Tests

```bash
cd backend && ./mvnw test
cd frontend && flutter analyze
cd frontend && flutter test
```

## Installation sur Android

Chaque [release GitHub](https://github.com/MyAm-org/MyAm/releases) publie un APK (`myam-<version>.apk`).

1. Télécharger le fichier `.apk` depuis la release sur l'appareil Android.
2. À l'ouverture, si demandé, autoriser l'installation d'apps depuis cette source (Paramètres > Applications > Accès spécial > Installer des applications inconnues).
3. Ouvrir le fichier téléchargé et confirmer l'installation.

## Installation sur iPhone via SideStore

On publie aussi un IPA non signé (`myam-<version>.ipa`), installable sans compte Apple Developer payant via [SideStore](https://sidestore.io/).

### Prérequis :

- Un iPhone/iPad avec iOS 15+ et un ordinateur (Windows, macOS ou Linux)
- Un Apple ID et une connexion Wi-Fi
- [iloader](https://docs.sidestore.io/docs/installation/prerequisites) installé sur l'ordinateur, et l'app `LocalDevVPN` installée et connectée sur l'appareil iOS

Étapes :

1. Connecter l'iPhone/iPad à l'ordinateur, ouvrir `iloader` et se connecter avec l'Apple ID.
2. Sélectionner l'appareil puis "Install SideStore (Stable)".
3. Sur l'appareil : Réglages > Général > VPN & Device Management, faire confiance à l'app liée à l'Apple ID, puis activer le "Developer Mode" (Confidentialité et sécurité) et redémarrer.
4. Ouvrir `LocalDevVPN` et se connecter, puis ouvrir SideStore et se connecter avec le même Apple ID.
5. Dans SideStore, importer le fichier `.ipa` téléchargé depuis la [release GitHub](https://github.com/MyAm-org/MyAm/releases) pour l'installer sur l'appareil.

Voir la [documentation officielle SideStore](https://docs.sidestore.io/docs/installation/install) pour les détails (prérequis par OS, dépannage, etc.).

## Flux Git

Branche (`feat/...`, `fix/...`, `chore/...`), commit, push, puis Pull Request vers `main`.
