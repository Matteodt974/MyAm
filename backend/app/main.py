from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import routes_health, routes_scan
from app.core.config import settings

app = FastAPI(title=settings.app_name, version="0.1.0")

# CORS large en dev pour que l'app Flutter (autre origine) puisse appeler l'API.
# À RESTREINDRE avant la prod : remplace ["*"] par tes domaines réels.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(routes_health.router)
app.include_router(routes_scan.router)


@app.get("/")
async def root():
    return {"app": settings.app_name, "docs": "/docs"}
