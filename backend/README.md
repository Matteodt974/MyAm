# Backend MyAm

API Spring Boot de MyAm. Elle expose les endpoints de scan sur le port `8080`.

- Java 21
- Spring Boot 3.3
- Maven wrapper `./mvnw`

## Lancer

```bash
cp .env.example .env
./mvnw spring-boot:run
```

Pour l'analyse de photo de plat, remplir `GEMINI_API_KEY=` dans `.env`, puis redemarrer le backend.

Swagger : http://localhost:8080/docs

Test rapide :

```bash
curl -X POST http://localhost:8080/v1/scan/barcode \
  -H "Content-Type: application/json" \
  -d '{"ean": "3017620422003"}'
```

## Docker

```bash
cp .env.example .env
docker compose up --build
```

Ports hotes : Postgres `5433`, LibreTranslate `5001`.

## Frontend

```bash
cd ../frontend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Tests

```bash
./mvnw test
```

## Structure

- `api/` : controleurs REST
- `config/` : configuration Spring
- `dto/` : objets d'entree et de sortie
- `service/` : appels externes et logique metier
