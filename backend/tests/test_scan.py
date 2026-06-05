"""Tests de l'endpoint UC5 — POST /v1/scan/dish.

On ne teste pas /v1/scan/barcode ici : il appelle Open Food Facts (service
externe) et ne doit pas dependre du reseau en CI. L'endpoint /dish, lui, est
auto-suffisant (il ne fait qu'inspecter le fichier recu).
"""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

_FAKE_JPEG = b"\xff\xd8\xff\xe0\x00\x10JFIFfakejpegbytes"


def test_scan_dish_accepts_image():
    files = {"image": ("plat.jpg", _FAKE_JPEG, "image/jpeg")}
    resp = client.post("/v1/scan/dish", files=files)

    assert resp.status_code == 200
    data = resp.json()
    assert data["filename"] == "plat.jpg"
    assert data["content_type"] == "image/jpeg"
    assert data["size_bytes"] == len(_FAKE_JPEG)
    assert data["status"] == "not_implemented"
    assert data["candidates"] == []
    # Contrat JSON figé (doit rester identique au backend Spring).
    assert set(data.keys()) == {
        "filename",
        "content_type",
        "size_bytes",
        "status",
        "message",
        "candidates",
    }


def test_scan_dish_rejects_non_image():
    files = {"image": ("notes.txt", b"hello", "text/plain")}
    resp = client.post("/v1/scan/dish", files=files)

    assert resp.status_code == 400
