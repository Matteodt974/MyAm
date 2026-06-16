# Spécification Produit – Clone de l'écran principal Yuka (Flutter)

## Objectif

Construire un écran principal inspiré de l'expérience Yuka, développé en Flutter et compatible iOS et Android.

L'objectif est de fournir à l'agent de développement toutes les informations nécessaires pour :

- reproduire l'expérience utilisateur principale ;
- intégrer une caméra temps réel en arrière-plan ;
- permettre le scan de codes-barres et QR codes ;
- permettre la prise de photo d'un plat ;
- afficher un espace profil utilisateur ;
- connecter automatiquement les fonctionnalités de scan aux routes API existantes du projet ;
- analyser la structure du repository afin d'identifier les services, repositories, clients HTTP et endpoints déjà présents.

---

# Référence UX

L'écran principal doit fonctionner comme l'écran de scan de Yuka.

## Structure générale

### Zone principale

La caméra occupe 100% du fond de l'écran.

Le flux vidéo doit être affiché en plein écran derrière toute l'interface.

Utiliser :

- mobile_scanner
- Repository : https://github.com/juliansteenbakker/mobile_scanner

La prévisualisation caméra doit être visible en permanence et constituer le fond principal de l'application.

---

# Contraintes techniques

## Flutter

Le développement doit être réalisé avec Flutter.

Le code doit être compatible :

- iOS
- Android

L'implémentation doit être prête pour la production.

---

## Caméra

Utiliser exclusivement la librairie :

https://github.com/juliansteenbakker/mobile_scanner

Exigences :

- Permissions Android gérées.
- Permissions iOS gérées.
- Ouverture automatique de la caméra.
- Gestion du cycle de vie (pause/reprise).
- Fonctionnement réel sur appareil physique.
- Gestion des QR Codes.
- Gestion des codes-barres classiques.
- Prévisualisation plein écran.

---

# Navigation basse

En bas de l'écran doit se trouver une barre de navigation personnalisée inspirée du croquis fourni.

Cette barre contient 3 sections :

## 1. Picture

Position : gauche

Fonction :

Permettre à l'utilisateur de prendre une photo d'un plat ou d'un aliment.

Comportement attendu :

- Ouverture du mode capture photo.
- Capture d'image.
- Envoi vers l'API d'analyse alimentaire si disponible.
- Prévoir une architecture permettant de brancher facilement l'API d'analyse.

Libellé :

```text
Picture
```

---

## 2. Scan

Position : centre

Fonction :

Scanner :

- code-barres
- QR code

Mode par défaut de l'application.

Libellé :

```text
Scan
```

---

## 3. Profile

Position : droite

Fonction :

Accès au profil utilisateur.

Libellé :

```text
Profile
```

---

# Animation de sélection

La barre inférieure doit posséder un indicateur animé.

Comportement :

- déplacement fluide entre les trois onglets ;
- animation de type slider ;
- transition moderne ;
- conservation de l'état sélectionné.

Exemples d'animation acceptés :

- AnimatedPositioned
- AnimatedAlign
- PageController synchronisé

L'animation doit être fluide à 60 FPS.

---

# Architecture Flutter attendue

L'agent doit analyser le projet et identifier automatiquement :

## Structure

- lib/
- features/
- core/
- services/
- repositories/
- data/
- domain/
- presentation/

ou toute autre architecture existante.

---

## Réseau

Identifier :

- Dio
- Retrofit
- Chopper
- HttpClient
- GraphQL
- API REST

Déterminer comment les appels API sont actuellement réalisés.

---

## Authentification

Identifier :

- Token JWT
- OAuth
- Session
- Headers personnalisés

Réutiliser le mécanisme déjà présent.

---

# Intégration du scan

Lorsqu'un code-barres est détecté :

1. récupérer la valeur scannée ;
2. empêcher les scans multiples simultanés ;
3. appeler l'API existante ;
4. afficher le résultat ;
5. gérer les erreurs réseau.

Pseudo-flux :

```text
Camera
    ↓
mobile_scanner
    ↓
BarcodeDetected
    ↓
API Product Lookup
    ↓
Response
    ↓
UI Result
```

---

# Analyse automatique du repository

L'agent doit parcourir le projet afin de trouver :

## Routes API

Identifier automatiquement :

- endpoints ;
- services ;
- repositories ;
- clients HTTP.

Exemples :

```text
GET /product/{barcode}
POST /scan
POST /food-analysis
```

Les exemples ci-dessus sont illustratifs : l'agent doit découvrir les routes réellement présentes dans le repository.

---

## Connexion du scanner

L'objectif est que le scan fonctionne immédiatement avec l'infrastructure existante.

L'agent doit :

- localiser les appels API ;
- identifier les modèles de données ;
- identifier les DTO ;
- identifier les repositories ;
- connecter le résultat du scanner à la route appropriée.

---

# UI attendue

## Hiérarchie

```text
Scaffold
 └── Stack
      ├── MobileScanner (plein écran)
      ├── Overlay UI
      └── Bottom Navigation personnalisée
```

---

## Bottom Navigation

```text
+-----------------------------------+
| Picture | Scan | Profile          |
+-----------------------------------+
```

Avec :

- indicateur animé ;
- coins arrondis ;
- design moderne ;
- compatible dark mode ;
- compatible light mode.

---

# Résultat attendu

Le livrable doit fournir :

1. Une caméra plein écran fonctionnelle.
2. Un scan QR et code-barres fonctionnel.
3. Une navigation basse animée à 3 sections.
4. Une architecture Flutter propre.
5. Une intégration avec les routes API existantes.
6. Une analyse automatique de la structure du repository.
7. Un code compatible Android et iOS.
8. Une solution prête à être exécutée et testée sur appareil réel.
