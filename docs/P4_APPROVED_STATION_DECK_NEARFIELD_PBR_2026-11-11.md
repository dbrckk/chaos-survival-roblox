# P4 — Matériaux industriels PBR 2K des socles de station en vraie 3D

**11 novembre 2026** — Base `f473fd2ef2595d3e947f0ff0e3e73f567bca0515`. Cette modification ne crée
pas de modèles/assets Roblox et ne publie pas automatiquement la Place.

## Problème identifié dans le dépôt

Les inserts `ApprovedPerimeterStationDeckInlayMeshKit` ont déjà remplacé
l'unique base plate `InlaidStationBase` des stations proches par
l'asset original triangulé **Approved `72507987666671`** (sept
MeshParts). Cependant, la liste d'owners connue du module
`PremiumNearfieldPbrKit` ne contenait pas ce dossier : il était
**impossible de recevoir les finitions 2K du système nearfield**
sur ces nouveaux socles.

## Correction

- Ajouter l'owner local
  `ApprovedPerimeterStationDeckInlaysLocal` et l'ID
  `72507987666671` à la whitelist **des cinq variantes**.
- Le module PBR existant vérifie toujours, avant de monter des
  matériaux, la provenance exacte du Model, ses sept vrais
  MeshParts non physiques, la distance caméra, l'identité
  de l'arène et les quatre familles de textures sérialisées
  dans `default.project.json`.
- Les **16 images 2K originales déjà approuvées** (color,
  normal, roughness, metalness) ne changent **pas** et ne
  sont jamais réimportées ou écrites par Luau.
- Les parties `SIGNAL`, `CARBON`, `GRIP` et `GLASS` sont
  exclues de la surcouche PBR : ni la lisibilité des alertes,
  ni les six éléments natifs de lumière, lentille ou
  orientation ne sont modifiés.
- Le montage PBR ne change jamais le modèle de base en
  collider ni n'ajoute de lumière, RenderStepped ou requête
  AssetService. La texture facultative est supprimée avec
  restitution des SurfaceAppearance d'origine lors d'un
  changement de carte, d'une pression GPU ou d'un
  refus de rendu PBR par le joueur.

## Plafonds GPU inchangés

`PremiumNearfieldPbrKit.budget()` maintient les **mêmes**
budgets partagés à toutes les sculptures originales à proximité :

| Niveau | Sans pression | Pression 1 | Pression 2 |
| --- | ---: | ---: | ---: |
| Low | 0 | 0 | 0 |
| Medium tactile | 2 | 1 | 0 |
| Medium PC | 3 | 1 | 0 |
| High tactile | 4 | 2 | 0 |
| High PC | 6 | 3 | 0 |

Il s'agit de **modèles maximum** ayant des SurfaceAppearance
supplémentaires, partagés avec les structures PBR précédentes.
Une station peut être sculptée sans recevoir de PBR 2K lorsque
toutes les places sont prises par d'autres modèles plus proches.

## Vérification

Contrat source **déjà existant** :
`tools/verify_premium_nearfield_pbr.py`, vérifiant les cinq
allowlists, l'ID modéré Approved dans le registre, la connexion
du nouveau module à la passe LOD, le plafond PBR, la
protection des noms de matériaux et la restauration des
apparences d'origine. Le workflow de régression PBR observe
également l'owner inlay.

Ces source checks n'affirment pas que l'apparence est chargée
à l'écran dans Roblox Studio ni que les FPS sont stables
sur Android. Build Validation, tests Roblox Engine et
publication sur SHA exact restent requis.
