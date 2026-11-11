# P4 — Arbitrage visuel réel des modèles 3D Android Low

**Date :** 11 novembre 2026. **Statut :** changement GitHub, non publié sur Roblox.

## Défaut constaté dans le code

Trois sources 3D originales de sept `MeshPart` existaient déjà pour
l'habillage de proximité : la carapace de route (`PremiumPlatformSideMeshKit`),
le carénage intégral du hub (`PremiumLargeDeckHullMeshKit`) et la
trappe supérieure (`PlatformFinishKit`). Quatrième candidat :
le véritable treillis Towers, deux modules de sept MeshParts.

La succession précédente de sélections imposait une priorité fixe :
`bridge > hatch > hub > carapace`. **Une passerelle Towers située à
120 studs pouvait ainsi réserver tout le budget Low alors qu'une trappe
ou une carapace était à cinq studs du joueur.** Sur Crossroads, une
trappe disponible sur `Platform1` pouvait évincer le grand carénage
18×18 de cette même plateforme, même sans avantage de visibilité.
Cela réduisait la qualité visuelle effective, malgré des assets
authentiques déjà présents.

## Réparation

- Sélection des **quatre familles sources vérifiées avant arbitrage** :
  le code de provenance et les contraintes propres à chaque kit
  restent la seule porte d'entrée.
- Sous Low uniquement, calcul de la **distance réelle de la caméra**
  à chaque candidat déjà sélectionné. Sélection déterministe en cas
  d'égalité de distance, sans rafraîchissement par image.
- **Pont Towers** : ses 14 MeshParts ne sont prioritaires que si
  le pont est à moins de 16 studs au-delà du plus proche modèle
  de premier plan. Si aucune autre famille source n'est valide,
  le pont peut conserver sa sélection initiale à moins de 125 studs.
- **Surfaces Low** : le carénage central 18×18 garde un léger avantage
  sur une trappe ou carapace de même distance (marge de 12 studs)
  pour conserver sa silhouette monumentale ; les carapaces ne
  consomment plus leur slot derrière une trappe nettement plus proche.
- **Caméra plongeante** : une orientation fortement descendante
  (`LookVector.Y < -0.50`) augmente la priorité des vraies
  sculptures supérieures, pour privilégier un relief qui sera
  effectivement visible depuis le dessus.
- Les sets non gagnants sont supprimés **avant de cloner des modèles**,
  pas après. Aucune instance ou texture nouvelle, aucun ID asset
  et aucune boucle graphique ajoutés.
- Les **deux modules Low 7+7** restent exclusifs : soit une
  Skybridge originale de 14, soit un habillage de proximité de
  sept et une structure support/LongCradle de sept au maximum.
  La pression graphique (`OptionalVfxPressure >= 1`) continue de
  démoter tous ces candidats optionnels.
- **Medium/High : sélection et plafonds inchangés.** Aucune
  modification serveur, collision, catastrophes ou avertissements.

## Cas pratiques à vérifier dans Roblox Engine

| Situation | Priorité attendue |
| --- | --- |
| Towers : Skybridge à 110 studs, trappe à 8 | Trappe et éventuellement grande structure |
| Towers : Skybridge à 12 studs, trappe à 8 | Skybridge authentique de 14 MeshParts |
| Crossroads : hub et trappe sur le même deck | Grand carénage 18×18 |
| Caméra fortement plongée, trappe nettement proche | Trappe supérieure sculptée |
| Source 3D non validée/streamée tardivement | Repli visuel natif ; pas de source fictive |
| Pression 1 ou 2 sur Android Low | Aucun de ces modèles 3D optionnels |
| Medium/High | Sélections historiques et limites conservées |

Les vérifications statiques sont dans
`tools/verify_original_3d_budget_census.py` et déclenchées depuis
`original-3d-budget-census-regression.yml`. La validation dans
Roblox Engine, les captures comparatives et les FPS/p95 Android
réels restent nécessaires **avant publication publique**.
