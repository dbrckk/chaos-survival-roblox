# P4 — Grue portuaire géante sculptée, Harbor

**Étape source intégrée — 10 novembre 2026.** Le workflow [#42780163672](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42780163672) a authentifié l'OBJ/glTF original (**2 940 triangles, sept matériaux, 40,8 × 14,0425 × 9,141 studs**) et créé le Model Roblox propriétaire **`124368710235343`**, réellement modéré **Approved**. Le nouveau kit serveur/client est branché au jeu ; voir [le contrat de montage P4](P4_RUNTIME_HARBOR_MEGAGANTRY_2026-11-10.md). Le reste de cette page décrit également l'étape de conception antérieure. La source intégrée ne constitue pas un rendu Roblox Engine vérifié ou une Place publique mise à jour.


**10 novembre 2026 — création d'un Model original ; aucune mise à jour de Place publique.**

## Source réelle et cible

La fonction `addArenaSignatureMegastructure` de `src/server/MapBuilder.lua` pour Harbor crée une structure nord non physique. Les trois grandes formes primitives visuellement dominantes sont :

| Nom natif | Classe | Dimensions (studs) | Centre local |
| --- | --- | --- | --- |
| QuayCraneSpanningBeam | Part | 41 × 2,1 × 4,4 | (0 ; 43,5 ; 0) |
| QuayCraneCounterweight | Part | 7 × 5,8 × 7 | (-10 ; 48 ; 3) |
| QuayControlCab | Part | 7,2 × 5,4 × 5,2 | (4,8 ; 39,5 ; 0) |

Le volume englobant ces trois anciennes formes mesure exactement **41 × 14,1 × 9,1 studs**, centre local **(0 ; 43,85 ; 1,95)**. Les deux pieds de quai, les renforts inclinés, les treuils et les deux câbles verticaux, le mât, les empilements de conteneurs et les spreaders restent natifs et intacts. **Aucune interaction joueur, physique du quai ou danger n'est modifiée.**

## Sculpture originale

`tools/generate_original_signature_harbor_gantry.py` crée une géométrie véritablement triangulée : longue poutre de grue à quatorze facettes, longerons extérieurs et réseaux ajourés de câbles, contrepoids forgé avec ailettes usinées, cabine vitrée en retrait avec montants en 3D, attaches, traverses, plaques et signalisation. Sept matériaux PBR industriels originaux (ARMOR, BRUSHED, CARBON, GRIP, ALLOY, CERAMIC, SIGNAL), sans générer de Roblox Parts ou télécharger de géométrie tierce.

Le workflow `.github/workflows/one-time-original-harbor-megagantry-20261110.yml` reproduit la source OBJ, la conversion glTF et les UV/normales/tangentes, vérifie les dimensions et le hash, puis importe uniquement un Model créateur autorisé. Pas d'identifiant inventé : le montage client ne peut être écrit qu'après un reçu Roblox `Moderation: Approved`.

## Montage conditionnel attendu

Un seul Model source doit remplacer les **trois grandes natives comme un ensemble atomique**. Le client devra vérifier la vraie carte Harbor, le vrai modèle `ArenaSignatureMegastructure`, les dimensions, CFrames et propriétés non physiques de ces natives, ainsi que les treuils, jambes et câbles préservés. Les sept MeshParts montés seront non collisionnels et sans nouvelles boucles LOD, avec restauration native sur source absente, streaming incomplet, base réduite et pression GPU. Low garde les primitives.

**Le dépôt ne contient pas à cette étape une publication Roblox Place ni un benchmark Android.**
