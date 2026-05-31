from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
async def health():
    """Utilisé par Render et docker-compose pour vérifier que l'API est vivante."""
    return {"status": "ok"}
