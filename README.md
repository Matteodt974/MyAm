# Allergies Mobile App — INM5151 (UQAM)

Application mobile de scan **alimentaire & cosmétique** : code-barres / étiquettes / menus →
fiche produit, **score nutritionnel /100** et **détection d'allergènes**.

**Monorepo :**
- [`backend/`](backend/) — API **FastAPI** (Python) + Docker Compose (Postgres, LibreTranslate, OCR à venir).
- [`frontend/`](frontend/) — application **Flutter** (`scan_app`).

Spécification du projet (source de vérité) : voir [objectifs.md](objectifs.md).

---

## 1) Prérequis (à installer une fois par machine)

Les dépendances **du code** (`pip` et `pub`) s'installent automatiquement plus bas. Ce que chacun doit
installer lui-même, c'est **l'outillage** :

| Outil | Version cible | Pourquoi | Où |
|---|---|---|---|
| **Git** | récent | cloner / PR | git-scm.com |
| **Flutter SDK** (inclut Dart) | **3.44.x stable** (Dart 3.12) | app mobile | docs.flutter.dev/get-started/install → puis `flutter doctor` |
| **Python** | **3.11 ou 3.12** | backend | python.org (cocher « Add to PATH » sous Windows) |
| **Docker Desktop** | récent (Compose v2 inclus) | Postgres + LibreTranslate | docker.com/products/docker-desktop |
| **Android Studio** | récent | SDK + émulateur Android, puis `flutter doctor --android-licenses` | developer.android.com/studio |
| **Xcode + CocoaPods** | macOS uniquement | build/simulateur iOS (`sudo gem install cocoapods`) | App Store |
| Éditeur | — | VS Code (extensions *Flutter*, *Dart*, *Python*) ou Android Studio / PyCharm | — |

Vérifie ton environnement Flutter avec `flutter doctor` (corrige tout ce qui n'est pas ✅ pour les
plateformes que tu vises). Sous Windows : pas d'iOS → développe sur Android / web.

---

## 2) Cloner

```bash
git clone git@github.com:Matteodt974/Allergies_mobile_app.git
cd Allergies_mobile_app
```

---

## 3) Backend (FastAPI) — `backend/`

**Étape commune : crée ton `.env` depuis le modèle**

```bash
cd backend
cp .env.example .env          # Windows (cmd) : copy .env.example .env
```

**Option A — sans Docker (itération rapide de l'API) :**

```bash
python3 -m venv .venv
source .venv/bin/activate      # Windows PowerShell : .venv\Scripts\Activate.ps1
                               # Windows cmd        : .venv\Scripts\activate.bat
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**Option B — avec Docker (API + Postgres + LibreTranslate) :**

```bash
docker compose up --build      # 1er lancement long : LibreTranslate télécharge les modèles en/fr/zh
```

**Vérifier que ça tourne :**

```bash
# Swagger : http://localhost:8000/docs
curl http://localhost:8000/health
curl -X POST http://localhost:8000/v1/scan/barcode \
  -H "Content-Type: application/json" -d '{"ean":"3017620422003"}'   # Nutella
```

Tests backend : `pytest` (depuis `backend/`, venv activé) — *aucun test pour l'instant*.

> **Notes** : le service **OCR (UC1)** est encore commenté dans `docker-compose.yml` (pas d'image prête) —
> c'est normal. La **base de données** n'est pas encore branchée (SQLAlchemy commenté dans
> `requirements.txt`) : l'API démarre sans.

---

## 4) Frontend (Flutter) — `frontend/`

```bash
cd frontend
flutter pub get                # installe les dépendances pub
flutter run                    # lance sur l'appareil / émulateur sélectionné
```

Pour viser le bon backend selon la cible, passe `API_BASE_URL` :

```bash
# Émulateur Android :
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
# Téléphone physique (même Wi-Fi) :
flutter run --dart-define=API_BASE_URL=http://<IP-LAN-de-ta-machine>:8000
```

(défaut = `http://10.0.2.2:8000`, voir `lib/core/constants/api_endpoints.dart`)

Autres commandes utiles :

```bash
flutter analyze                                            # lint
flutter test                                               # tests
dart run build_runner build --delete-conflicting-outputs   # dès qu'il y a des modèles freezed/json
                                                           # (.g.dart / .freezed.dart ne sont PAS versionnés)
```

---

## 5) Flux de travail d'équipe

Branche (`feat/...`, `fix/...`, `chore/...`) → commit → push → **Pull Request vers `main`** →
CI verte + 1 review → merge.

**Personne ne pousse directement sur `main`.** Chaque PR déclenche la CI (lint + tests backend & frontend).
