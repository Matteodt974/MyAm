# Backend MyAm

API Spring Boot de MyAm. Expose les endpoints de scan sur le port `8545`.

- Java 21
- Spring Boot 3.3
- Maven wrapper `./mvnw`

## Variables d'environment nécessaires

`JWT_SECRET` et `ENCRYPTION_MASTER_KEY` sont **obligatoires** : le backend refuse de démarrer (`IllegalStateException`) si l'un des deux fait moins de 32 caractères. `.env.example` les fournit comme des placeholders vides/masqués, remplace-les par de vraies valeurs (ex. `openssl rand -base64 48`) avant de lancer le backend.

Pour l'analyse de photo de plat, remplir `GEMINI_API_KEY=` dans `.env`, puis redemarrer le backend.
Pour les donnees nutritionnelles (UC7), `FDC_API_KEY=DEMO_KEY` suffit en developpement ; obtenir une cle sur https://fdc.nal.usda.gov/api-guide.html pour la prod.

## Lancer

### Lancer avec maven

```bash
cp .env.example .env
./mvnw spring-boot:run
```

### Lancer avec Docker

`docker-compose.yml` bind sur `127.0.0.1` uniquement (c'est ce qui est déployé en prod, derrière nginx: voir `deploy/nginx/api-myallergymon.conf`).

Pour tester depuis un téléphone physique sur le LAN :

```bash
cp .env.example .env
cp docker-compose.override.yml.example docker-compose.override.yml
docker compose up --build
```

## Tests

### Tests unitaires

```bash
./mvnw test
```

### Test rapide de déploiement

```bash
curl -X POST http://localhost:8545/v1/scan/barcode \
  -H "Content-Type: application/json" \
  -d '{"ean": "3017620422003"}'
```

## Documentation

- Swagger : http://localhost:8545/docs
