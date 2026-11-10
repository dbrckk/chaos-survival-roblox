# P4 — Crêtes extérieures sculptées : quatre profils, douze WedgeParts

**Date : 10 novembre 2026.** Modèles 3D originaux et import créateur vérifiés. Ce commit ne publie pas la Place Roblox.

## Périmètre exact

`MapBuilder.addExteriorCornerRidges` fabrique quatre `ExteriorRidgeNW/NE/SW/SE`, chacun avec **trois** natives `WedgePart` (`Ridge1..3`), sans aucune collision et en dehors du terrain jouable. Ces WedgeParts avaient encore les formes angulaires Roblox par défaut. Le nouveau kit `ApprovedExteriorRidgeMeshKit` vise donc **12 éléments visibles par carte**. Comme la même famille existe dans cinq variantes d'arène, **60 occurrences-source possibles** sont éligibles, mais une seule variante/12 instances est présente à la fois.

## Quatre vrais modèles source distincts

| Coin | Hauteurs natives `Ridge1..3` | Dimensions source OBJ X×Y×Z | Offset du centre source X/Y/Z | Model asset Roblox |
|---|---|---|---|---|
| NW | 17, 13, 9 | 37.45768 × 15.9 × 33.90254 | -1.55967, 6.53, -1.6353 | `123836720232695` |
| NE | 12, 19, 15 | 37.90254 × 17.78 × 33.45768 | 1.6353, 7.47, -1.55967 | `83853948389204` |
| SW | 16, 12, 19 | 37.90254 × 17.78 × 33.45768 | -1.6353, 7.47, 1.55967 | `108491064314671` |
| SE | 11, 18, 14 | 37.45768 × 16.84 × 33.90254 | 1.55967, 7.0, 1.6353 | `83023096720529` |

Chaque profil : **6 252 vrais triangles**, sept matériaux PBR, maillage rocheux triangulé irrégulier, structure métallique en relief, contreventements, inserts céramiques, signaux de couleur. Source : `tools/generate_original_exterior_ridges.py`. Les quatre vérifications OBJ/glTF des normales, UV, tangentes, tailles et hash ont réussi dans [GitHub Actions #42854203855](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42854203855). Les quatre assets Roblox ont été créés par le véritable compte propriétaire avec `Moderation: Approved`.

## Contrat client/serveur

Le serveur `PremiumExteriorRidgeAssets` importe quatre assets avec `AssetService.LoadAssetAsync`, sanitize les modèles, exige **sept MeshParts** non physiques et vérifie les bornes source attendues.

Le client `ApprovedExteriorRidgeMeshKit` vérifie l'identité de la carte, la variante, les quatre owners et les **12 WedgeParts** : taille exacte, position, ancrage, propriété non collisionnelle, orientation issue de `math.atan2(sx,sz)` et rotation supplémentaire de ±0,32 radian, hauteur calculée selon les signes du coin. Il utilise l'offset exact de chaque source pour placer les MeshParts au bon endroit, sans nouveau pivot arbitraire.

La substitution est **mount-before-hide** ; les valeurs initiales de transparence `0.11 / 0.15 / 0.19` sont conservées et restaurées automatiquement sur carte modifiée, streaming incomplet, source manquante, qualité Low ou forte pression GPU.

Le kit partage la boucle LOD existante, classée par distance caméra : **Medium : 2 coins max**, **High : 4 coins max (3 sur Android tactile)** ; charge GPU élevée peut réduire ou couper ces clones. **28 MeshParts max** pour les quatre coins, soit **25 008 triangles** pour l'ensemble optionnel ; le profil Low conserve les 12 natives et zéro MeshPart ajouté.

Compteurs client : `LocalApprovedExteriorRidgeModelCount` (0–4) et `LocalExteriorRidgePrimitivesReplaced` (0–12). Le test source CI `tools/verify_exterior_ridges_fallback.py` vérifie les quatre profils OBJ, vrais IDs, transformations natives et repli transparent.

**Limites de validation :** la fusion GitHub n'est pas une publication de Roblox Place et les contrôles statiques ne remplacent pas les tests de rendu Roblox Studio, performance GPU, visibilité en streaming et FPS Android. Les MeshParts restent un habillage purement cosmétique sans action sur les collisions, les bots ou le gameplay.
