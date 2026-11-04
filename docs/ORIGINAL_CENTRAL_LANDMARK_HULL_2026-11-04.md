# Châssis 3D original des hubs centraux 18 × 18 — 4 novembre 2026

Source : `tools/generate_original_large_deck_support.py --model large_deck_hull`, OBJ triangulé créé dans le dépôt, converti en glTF 2.0 avec sept primitives matériaux (ARMOR, BRUSHED, CARBON, GRIP, ALLOY, CERAMIC et SIGNAL). Les supports détaillés des cinq arènes sont traités séparément par `generate_original_large_supports.py`, afin de ne pas charger deux bibliothèques de colonnes concurrentes.

**Véritable import propriétaire Roblox :** `125929150866282`, état de modération **Approved**, preuve [GitHub Actions #41809088464](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41809088464), source-gate et création du Model réussis.

## Intégration

- `src/server/PremiumLargeDeckHullAssets.lua` charge exclusivement cet ID, assainit le Model via `OriginalMeshScenery.sanitize`, exige 1 à 12 `MeshPart` et les dimensions d'une enveloppe d'environ 18 × 3 × 18 studs, refuse scripts et native Parts. L'import est différé afin de ne pas perturber les assets de gameplay.
- `src/client/PremiumLargeDeckHullMeshKit.lua` monte la sculpture complète sur un **vrai** `PlatformN` compatible, dimensions collidables 16,3 à 20 studs, ratio carré et index historique inférieur ou égal à 24. Le mesh est intégralement sous la surface physique, sans collisions, événements Touch ou Query.
- `src/client/arena-platform-identity.client.lua` donne priorité au châssis original sur le kit des petits decks, en réutilisant exactement les soudures, `CollapsePhase`, et `bindRouteFootprint` existants. Si le Model est absent ou rejeté, l'ancienne géométrie reste en place. Un observateur déclenche la reconstruction à la réception tardive de `LargeDeckHull`.
- Les deux niveaux de qualité Medium et High peuvent afficher les sept véritables `MeshPart` ; **Low ne les charge jamais dans la scène**. La fenêtre d'éligibilité cible le hub central et non des centaines de plateformes plus petites.
- Les anciennes `PlatformBevel` et `PlatformUnderFrame` ne sont masquées que lorsque le châssis authentifié a réellement été monté sur l'index de plateforme correspondant, par `PlatformNativeTrimReplacementKit`. Les colliders, panneaux de danger et rails lumineux conservent leurs traitements natifs.

## État honnête

Ce document atteste un source asset auteur approuvé et une intégration candidate dans GitHub **mais pas une publication dans le jeu public** ni une certification visuelle sur Android. Les tests source exact-SHA doivent être réussis après les dernières modifications et l'arène doit être inspectée en conditions réelles. Les géométries des grandes routes longitudinales et les piliers des cinq cartes restent un chantier séparé.

