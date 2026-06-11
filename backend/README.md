# INM5151 — Backend (Spring Boot)

Portage Java/Spring Boot du backend FastAPI ([../backend](../backend)) : **mêmes endpoints, même
contrat JSON**. Il tourne sur le **port 8080** (le backend FastAPI occupe 8000), donc les deux
backends peuvent fonctionner en parallèle.

- Java 21 · Spring Boot 3.3 · Maven (wrapper `./mvnw`)

## Lancer en local (sans Docker)

```bash
./mvnw spring-boot:run
```

Puis ouvre http://localhost:8080/docs (Swagger UI auto-généré).

Test rapide de l'endpoint barcode (Nutella) :

```bash
curl -X POST http://localhost:8080/v1/scan/barcode \
  -H "Content-Type: application/json" \
  -d '{"ean": "3017620422003"}'
```

## Lancer avec Docker (api + postgres + libretranslate)

```bash
cp .env.example .env
docker compose up --build
```

> Les ports hôtes de `db` (5433) et `libretranslate` (5001) diffèrent de la stack FastAPI
> (5432 / 5000) pour éviter les conflits : on peut donc lancer **les deux stacks en même temps**.

## Brancher le frontend Flutter sur ce backend

L'API est identique à celle du FastAPI ; il suffit de pointer l'URL de base sur le port 8080 :

```bash
cd ../frontend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # émulateur Android
# iOS / desktop : --dart-define=API_BASE_URL=http://localhost:8080
```

## Tests

```bash
./mvnw test
```

## Structure

```
src/main/java/com/uqam/inm5151/scan/
├── ScanApplication.java        # point d'entrée Spring Boot
├── config/
│   ├── AppProperties.java      # config via variables d'env (@ConfigurationProperties)
│   └── CorsConfig.java         # CORS ouvert (dev)
├── api/
│   ├── RootController.java     # GET /
│   ├── HealthController.java   # GET /health
│   ├── ScanController.java     # POST /v1/scan/barcode (proxy Open Food Facts)
│   └── ApiExceptionHandler.java# erreurs au format {"detail": "..."} (comme FastAPI)
├── dto/                        # BarcodeRequest / BarcodeResponse
└── service/
    └── OpenFoodFactsClient.java# appel HTTP à Open Food Facts
```

## À faire ensuite (parité avec la feuille de route FastAPI)

- Brancher PostgreSQL (Spring Data JPA) + Flyway/Liquibase → users, scans, allergies
- Auth JWT (Spring Security) → /v1/auth/register, /v1/auth/login
- Score /100 (formule 60/30/10) dans le service de scan
- Endpoints /scan/menu (OCR+traduction), /scan/label, /scan/cosmetic
