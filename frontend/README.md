# Frontend MyAm

Application Flutter de scan alimentaire et cosmétique.

## Prérequis

- Flutter SDK
- Android Studio / Xcode selon la plateforme cible

## Lancer

```bash
flutter pub get
flutter run
```

## Configuration

Par défaut, l'app pointe vers `http://10.0.2.2:8080`.

**Option 1 : variable d'environnement complète**

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

**Option 2 : hôte et port séparés (utile si un des options n'est pas changé)**

```bash
flutter run --dart-define=BACKEND_HOST=192.168.2.10 --dart-define=BACKEND_PORT=8082
```

**Option 3 : fichier `.env`** (lu par `scripts/run_android.sh` et `scripts/run_ios.sh`)

```bash
cp .env.example .env # Définir BACKEND_URL ou BACKEND_HOST/BACKEND_PORT
scripts/run_android.sh --debug -d 192.168.2.25:36207
```

## Tests

```bash
flutter analyze
flutter test
```
