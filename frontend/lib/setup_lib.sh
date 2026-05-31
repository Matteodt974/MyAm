#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Scaffolding de l'arborescence lib/ — projet INM5151 (Flutter, feature-first)
# À lancer DEPUIS le dossier lib/ :   bash setup_lib.sh
#
# Crée chaque dossier + un fichier _README.txt expliquant son rôle.
# Le _README.txt sert double emploi : (1) documentation, (2) permet à Git de
# versionner le dossier (Git ignore les dossiers vides).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# --- Garde-fou : on doit être dans lib/ (présence de main.dart) ---
if [[ ! -f "main.dart" ]]; then
  echo "❌ main.dart introuvable ici."
  echo "   Place-toi DANS le dossier lib/ avant de lancer ce script."
  exit 1
fi

# --- Helper : crée un dossier (récursif) + son _README.txt ---
make() {
  mkdir -p "$1"
  printf '%s\n' "$2" > "$1/_README.txt"
  echo "✅ $1"
}

# === app/ : châssis de l'application ===
make "app" \
  "app/ — Configuration globale de l'app : MaterialApp, thème et navigation. Contiendra app.dart, router.dart, theme.dart."

# === core/ : code transverse réutilisable, sans logique métier propre à une feature ===
make "core/constants" \
  "core/constants/ — Valeurs constantes globales (URLs d'API, clés). Contiendra api_endpoints.dart."
make "core/network" \
  "core/network/ — Client HTTP Dio et ses intercepteurs (JWT, logs, retry). Contiendra dio_client.dart."
make "core/errors" \
  "core/errors/ — Exceptions et types d'erreurs personnalisés, et leur gestion centralisée."
make "core/utils" \
  "core/utils/ — Fonctions utilitaires génériques (formatage, validation, helpers) réutilisables partout."

# === shared/ : éléments partagés entre plusieurs features ===
make "shared/widgets" \
  "shared/widgets/ — Composants UI réutilisables entre features (AppButton, ScoreGauge…)."
make "shared/models" \
  "shared/models/ — Modèles de données communs à plusieurs features (User, ApiError…)."

# === features/ : un dossier par fonctionnalité (architecture feature-first) ===
# auth est découpée en 3 couches (clean architecture) ; les autres features
# pourront adopter le même découpage data/domain/presentation plus tard.
make "features/auth/data" \
  "features/auth/data/ — Couche DONNÉES de l'auth : appels API, sources de données, implémentations de repository."
make "features/auth/domain" \
  "features/auth/domain/ — Couche MÉTIER de l'auth : entités, contrats de repository, use cases. Indépendante du framework."
make "features/auth/presentation" \
  "features/auth/presentation/ — Couche UI de l'auth : écrans login/register, widgets, gestion d'état (Riverpod)."
make "features/profile_allergies" \
  "features/profile_allergies/ — UC6 : gestion du profil d'allergies de l'utilisateur (ajout/suppression)."
make "features/scan_menu" \
  "features/scan_menu/ — UC1 : photo d'un menu -> OCR + traduction."
make "features/scan_barcode" \
  "features/scan_barcode/ — UC2 : scan code-barres (mobile_scanner) + lookup Open Food Facts."
make "features/scan_food_label" \
  "features/scan_food_label/ — UC3 : photo d'étiquette -> calcul du score nutritionnel."
make "features/scan_cosmetic" \
  "features/scan_cosmetic/ — UC4 : photo de liste INCI ou code-barres -> analyse cosmétique (Open Beauty Facts)."
make "features/scan_dish" \
  "features/scan_dish/ — UC5 (stretch goal) : photo d'un plat préparé -> identification."

# === l10n/ : internationalisation ===
make "l10n" \
  "l10n/ — Internationalisation : fichiers de traduction fr/en (format ARB)."

echo ""
echo "🎉 Arborescence créée. Vérifie avec :"
echo "   find . -type d | sort"
