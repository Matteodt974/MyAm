# Backend MyAm

API Spring Boot de MyAm. Expose les endpoints de scan sur le port `8080`.

- Java 21
- Spring Boot 3.3
- Maven wrapper `./mvnw`

## Variables d'environment nécessaires

Pour l'analyse de photo de plat, remplir `GEMINI_API_KEY=` dans `.env`, puis redemarrer le backend.
Pour les donnees nutritionnelles (UC7), `FDC_API_KEY=DEMO_KEY` suffit en developpement ; obtenir une cle sur https://fdc.nal.usda.gov/api-guide.html pour la prod.

## Lancer

### Lancer avec maven

```bash
cp .env.example .env
./mvnw spring-boot:run
```

### Lancer avec Docker

```bash
cp .env.example .env
docker compose up --build
```

## Tests

### Tests unitaires

```bash
./mvnw test
```

### Test rapide de déploiement

```bash
curl -X POST http://localhost:8080/v1/scan/barcode \
  -H "Content-Type: application/json" \
  -d '{"ean": "3017620422003"}'
```

## Documentation

- Swagger : http://localhost:8080/docs
