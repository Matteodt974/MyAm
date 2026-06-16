# MyAm

Application Flutter de scan alimentaire et cosmetique.

## Lancer

```bash
flutter pub get
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

Pour un telephone physique, remplacer `10.0.2.2` par l'adresse LAN de la machine qui lance le backend.
Les scripts `scripts/run_android.sh` et `scripts/run_ios.sh` lisent aussi `frontend/.env`.

Le backend peut etre configure avec une URL complete :

```bash
flutter run --dart-define=BACKEND_URL=http://192.168.2.10:8082
```

ou avec une adresse IP / un nom d'hote et un port :

```bash
flutter run --dart-define=BACKEND_HOST=192.168.2.10 --dart-define=BACKEND_PORT=8082
```

`API_BASE_URL` reste accepte pour compatibilite.

Exemple avec `.env` :

```bash
cp .env.example .env
# Puis definir BACKEND_URL ou BACKEND_HOST/BACKEND_PORT dans .env.
scripts/run_android.sh --debug -d 192.168.2.25:36207
```

## Tests

```bash
flutter analyze
flutter test
```
