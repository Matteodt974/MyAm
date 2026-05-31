# INM5151 — Backend (FastAPI)

API du scanner alimentaire & cosmétique.

## Lancer en local (sans Docker)

```bash
python3 -m venv .venv
source .venv/bin/activate          # Windows : .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Puis ouvre http://localhost:8000/docs (Swagger auto-généré).

Test rapide de l'endpoint barcode (Nutella)

```bash
curl -X POST http://localhost:8000/v1/scan/barcode \
  -H "Content-Type: application/json" \
  -d '{"ean": "3017620422003"}'
```

## Lancer avec Docker (api + postgres + libretranslate)

```bash
cp .env.example .env
docker compose up --build
```

## Structure

```
app/
├── main.py              # point d'entrée FastAPI + CORS
├── core/config.py       # config via variables d'env (pydantic-settings)
└── api/
    ├── routes_health.py # GET /health
    └── routes_scan.py   # POST /v1/scan/barcode  (proxy Open Food Facts)
```

## À faire ensuite

- Brancher PostgreSQL (SQLAlchemy) + Alembic → users, scans, allergies
- Auth JWT (pyjwt) → /v1/auth/register, /v1/auth/login
- Score /100 (formule 60/30/10) dans routes_scan
- Endpoints /scan/menu (OCR+traduction), /scan/label, /scan/cosmetic
