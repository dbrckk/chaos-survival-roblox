# P4 — couverture 3D authentique dense des districts en qualité High

Mise à jour du 13 novembre 2026. Dépôt `dbrckk/chaos-survival-roblox`, branche `main`.

## Objectif visible

Chaque carte possède seize bâtiments de district d'origine. La qualité
graphique **High sur PC sans surcharge** avait des budgets de 12 façades
et 10 coques arrière/latérales. Les cinq cartes disposent déjà des
sources Roblox **créateur approuvées** : quatre profils de façade et une
source de coque latérale (six MeshParts). Aucun nouvel asset ni texture
n'est nécessaire pour élargir la couverture des façades visibles.

La sélection réutilise les propriétaires réels, les portes/fondations
authentifiées et la priorité existante face caméra, dans la même passe
`scenery-lod.client.lua`. Les indicateurs de jeu, portes fonctionnelles,
collisions, avertissements et scripts de catastrophe restent natifs.

| Qualité et mode | Façades 3D max | Coques 3D latérales max | Comportement |
|---|---:|---:|---|
| Low normal | 1 | 1 | Inchangé ; coque uniquement sur bâtiment dont la façade 3D existe |
| Medium normal PC | 5 | 4 | Inchangé |
| High normal PC | **16** (ancien 12) | **12** (ancien 10) | Jusqu'à 4 façades et 2 coques en plus ; uniquement si candidates en portée et sources approuvées |
| High tactile Android sans pression | **8** | **8** | Strictement inchangé |
| High tactile Android, pression 1 | **4** | **4** | Strictement inchangé |
| High PC, pression 1 | **6** | **5** | Maintien exact des anciens plafonds d'urgence |
| Pression 2, tous modes | 0 | 0 | Retrait immédiat des sculptures optionnelles, retour aux natives |

Les budgets globaux `VisualBudgetRules` restent **Low 440 Parts,
Medium 680, High 900**, sans nouveau dossier local. En High PC normal,
la capacité supplémentaire correspond à quatre clones existants de
façade et deux clones existants de coque, soit **des possibilités de
masquage**, pas la promesse de 16 modèles constamment affichés ni une
mesure de débit d'images. Le nombre réel dépend de la distance de caméra,
de l'asset source, des pièces réellement répliquées et du budget GPU.

## Contrôle et conditions d'acceptation

Le script source existant
`tools/verify_original_3d_budget_census.py` vérifie ces limites
ainsi que les plafonds tactiles et la relâche sous pression.
Le test moteur existant
`tests/engine/native-premium-fallback.spec.luau` vérifie la
nouvelle limite desktop High et l'ancienne limite Android.

Aucune physique, collision ou création de terrain n'a été changée ;
les prochains contrôles doivent confirmer le Build Validation,
les sept suites Roblox Engine et la cohérence des vrais rendus
High/Medium/Low sur PC/Android. **Les FPS et captures visuelles
client ne sont pas mesurés ici. Aucune publication publique n'est
déclenchée par cette modification.**
