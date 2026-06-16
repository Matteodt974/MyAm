# MyAm

Application mobile INM5151 pour scanner des produits alimentaires et cosmetiques.

- `backend/` : API Spring Boot.
- `frontend/` : application Flutter.

## Prerequis

| Outil             | Version cible    | Pourquoi                 |
| ----------------- | ---------------- | ------------------------ |
| Git               | recent           | cloner et contribuer     |
| Flutter SDK       | 3.44.x stable    | application mobile       |
| Java              | 21               | backend Spring Boot      |
| Docker Desktop    | recent           | services locaux          |
| Android Studio    | recent           | SDK et emulateur Android |
| Xcode + CocoaPods | macOS uniquement | iOS                      |
| Python            | 3.x              | pre-commit               |
| Node.js           | recent           | prettier                 |

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

## Flux Git

Branche (`feat/...`, `fix/...`, `chore/...`), commit, push, puis Pull Request vers `main`.
