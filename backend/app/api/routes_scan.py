"""UC2 — scan_food_barcode.

Endpoint RÉEL et fonctionnel : il interroge Open Food Facts et renvoie les
champs utiles. C'est ton premier "vrai" use case de bout en bout, sans BD,
sans OCR, sans rien d'autre à installer. Idéal pour valider que toute la
chaîne (Flutter -> API -> service externe) marche dès le jour 1.
"""
import httpx
from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel

from app.core.config import settings

router = APIRouter(prefix="/v1/scan", tags=["scan"])


class BarcodeRequest(BaseModel):
    ean: str


@router.post("/barcode")
async def scan_barcode(req: BarcodeRequest):
    """ UC2 - scan_food_barcode.

    <p>Endpoint REEL et fonctionnel : il interroge Open Food Facts et renvoie les champs utiles.
    Premier "vrai" use case de bout en bout (Flutter -> API -> service externe), sans BD ni OCR.
    Portage de backend/app/api/routes_scan.py.</p>"""
    url = f"{settings.off_base_url}/api/v2/product/{req.ean}.json"
    params = {
        "fields": "product_name,brands,nutriscore_grade,nova_group,"
                  "additives_tags,allergens_tags",
    }
    headers = {"User-Agent": settings.off_user_agent}

    async with httpx.AsyncClient(timeout=10) as client:
        try:
            resp = await client.get(url, params=params, headers=headers)
        except httpx.RequestError:
            raise HTTPException(status_code=502, detail="Open Food Facts injoignable")

    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Réponse OFF invalide")

    data = resp.json()
    if data.get("status") != 1:
        raise HTTPException(status_code=404, detail="Produit introuvable")

    p = data["product"]
    return {
        "ean": req.ean,
        "name": p.get("product_name"),
        "brands": p.get("brands"),
        "nutriscore": p.get("nutriscore_grade"),
        "nova_group": p.get("nova_group"),
        "additives_tags": p.get("additives_tags", []),
        "allergens_tags": p.get("allergens_tags", []),
        # TODO : calculer ici le score /100 (formule 60/30/10 du OpsCon)
    }


@router.post("/dish")
async def scan_dish(image: UploadFile = File(...)):
    """UC5 (stretch) — scan_dish : identification d'un plat à partir d'une photo.

    L'onglet "Picture" de l'app envoie ici une image en multipart (champ ``image``).
    L'identification réelle (LogMeal / CNN) n'est PAS encore branchée : on renvoie
    une réponse stub structurée, prête à être remplie au sprint 3. L'objectif est
    que le front ait un endpoint stable à appeler dès maintenant.

    Loi 25 / RGPD : l'image n'est JAMAIS persistée. On la lit seulement en mémoire
    pour en connaître la taille, puis elle est abandonnée (pas d'écriture disque).
    """
    if not (image.content_type or "").startswith("image/"):
        raise HTTPException(status_code=400, detail="Le fichier doit être une image")

    contents = await image.read()  # lecture en mémoire uniquement, aucun stockage

    return {
        "filename": image.filename,
        "content_type": image.content_type,
        "size_bytes": len(contents),
        "status": "not_implemented",
        "message": "Analyse de plat non encore disponible (UC5).",
        "candidates": [],
    }
