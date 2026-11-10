# P4 — Tours sud : les 7 derniers éléments primitifs couverts par des maillages originaux

**2026-11-10 — code GitHub intégré, Place Roblox non publiée ni testée dans Studio.**

## Asset original et vérification
Le pipeline [GitHub Actions #42840287655](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42840287655) a validé un vrai fichier OBJ puis glTF, **8 708 triangles**, **7 matériaux PBR** (ARMOR, BRUSHED, CARBON, GRIP, ALLOY, CERAMIC, SIGNAL), dimensions source **18,5 × 17,73 × 5,136 studs**, SHA256 source vérifié. Le Roblox Model créateur **`79666240429608`** est confirmé **Moderation: Approved**. Source : `tools/generate_original_south_towers_finishing.py`.

## Les 7 remplacements complémentaires
`ApprovedSouthTowersFinishingMeshKit.lua` cible, exclusivement sur le vrai `GeneratedMap/Arena` Towers et son `SouthHorizonMonument` :
- `Foundation` — Part 47×2×13, à (0,−1,0)
- `FloorInset` — Part 39×0,3×10, à (0,0,16,0)
- `WestLiftRail` — Part 0,42×30×0,6, à (−17,5,18,5,−3,7)
- `EastLiftRail` — Part 0,42×39×0,6, à (17,5,23,−3,7)
- `WestSuspension` — Part 0,9×16×1, rotation −26° autour de Z, centre (−10,31,0)
- `EastSuspension` — Part 0,9×16×1, rotation +26° autour de Z, centre (10,31,0)
- `TransferSignal` — WedgePart 7×2×2, à (3,5,26,5,−3)

Le serveur `PremiumSouthTowersFinishingAssets.lua` charge de façon asynchrone le Model vérifié et rejette tout contenu non-MeshPart, physique, scripté ou hors enveloppe attendue. Le kit client valide toutes les formes originales et l'existence des six formes déjà prises en charge par les deux autres kits. La sculpture est montée d'abord, puis les sept primitives natives masquées. La restauration des **Part et WedgePart** conserve chacune des transparences originales.

## Règles de sécurité et performances
- Les sept nouveaux MeshParts sont cosmétiques, non collisionnels, sans queries, sans touch, sans ombres.
- Une seule cadence LOD déjà existante : **Low=0**, Medium/High à distance acceptable, désactivation sous pression GPU et lorsque les assets ou la carte manquent.
- Pas de boucle RenderStepped additionnelle, pas d'impact réseau, bots, physique, dégâts ou progression.
- Trois kits indépendants, 13 noms natifs uniques et aucune superposition des cibles.
- Le test statique `tools/verify_south_towers_mesh_fallback.py` vérifie les 13 cibles, l'import approuvé, les points de restauration et le branchement au budget visuel.

## Portée réelle
**Towers sud : 13/13 primitives ont une variante 3D originale approuvée dans le code** — 2 `SkyTransfer` + `UnderslungLift`, 4 tours/couronnes, 7 finitions. **Ce n'est pas 100 % de toute la carte**, ni 100 % de conversion active à chaque instant : sur Low, les natives restent intentionnellement visibles. Aucun test graphique Roblox Studio ou FPS Android n'est inclus, et aucune publication de Place n'a eu lieu.
