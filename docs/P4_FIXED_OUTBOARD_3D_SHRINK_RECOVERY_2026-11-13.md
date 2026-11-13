# Chaos Survival — six familles de 3D fixes préservées pendant Shrinking Arena

**Date :** 13 novembre 2026 · **Dépôt :** `dbrckk/chaos-survival-roblox` · **Branche :** `main`.

## Cause réelle

Plusieurs modules client vérifiaient la taille **courante** de la dalle jouable pour décider d'afficher des sculptures 3D pourtant ancrées en dehors de la dalle, ou à une position fixe. La catastrophe `ShrinkingArena` réduit correctement `Base.Size.X/Z`. Le seuil original `318` (ou `160`) désactivait donc à tort des substitutions 3D déjà approuvées, et certaines vérifications de position calculées sur la nouvelle taille rejetaient également les natives authentiques.

`MapBuilder` attribue `OriginalSizeX` et `OriginalSizeZ` à la vraie `Base` lors de la création. Le contrôle corrigé exige la vraie Base ancrée/collidable de l'arène, une empreinte originale numérique d'au moins 318 studs, une dalle actuelle positive et aucune expansion au-delà du constructeur (tolérance .2 stud). **Le plancher de gameplay et ses collisions continuent à rétrécir normalement.**

## Six propriétaires réellement modifiés

| Module | Sculpture conservée et problème corrigé |
|---|---|
| `ApprovedFoundationChassisMeshKit` | Les 11 finitions natives d'un véritable socle de fondation restent candidates au remplacement par l'ancien châssis créateur approuvé, avec sélection Low à une seule source de 7 MeshParts |
| `ApprovedCinematicHorizonMeshKit` | Les onze silhouettes cinématiques possibles par variante utilisent le gabarit original dans leur validation d'authenticité ; les plafonds Low/Medium/High préexistants restent inchangés |
| `ApprovedMidgroundSkylineMeshKit` | Les quatre masses intermédiaires de Classic/Crossroads sont toujours contrôlées par rapport au véritable périmètre initial, sans accepter un faux bâtiment entré dans la zone jouable |
| `ApprovedAtmosphereColumnsMeshKit` | Les quatre piliers et quatre silhouettes d'angle par variante conservent leurs positions de construction, même après contraction du sol |
| `ApprovedAtmosphereCrownMeshKit` | L'unique couronne atmosphérique 3D Towers ne perd plus son remplacement authentique pendant la contraction |
| `ApprovedOrbitalSignatureRingMeshKit` | Les seize arcs natifs de l'anneau du réacteur Orbital utilisent la position originale de son centre pour autoriser le tore créateur de sept MeshParts |

Ces quantités sont **des cibles de source**, pas des modèles montrés simultanément. Les budgets, les distances caméra, la réduction par pression visuelle, la présence d'assets réels et le streaming conditionnent toujours les montages. Aucune nouvelle ressource 3D, collision, RemoteEvent, lumière ni boucle de rendu n'a été introduite.

## Vérifications et limites de preuve

- Le contrôle préexistant `tools/audit_visual_structure_sources.py` vérifie désormais la signature des dimensions et l'absence de l'ancien seuil de taille actuelle sur ces six modules.
- **[Recensement source et nouvelles assertions : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43437045925)**, commit `138817c414dacdfe88c3caa637a1d61cd9a305b9`.
- **[Recensement budget des modèles 3D Android : réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43436959835)**, commit `3be51807b15fb4371d752fdd2836b48978d18cc9`.
- Le recensement dénombre maintenant **19 kits visuels** contenant encore une condition statique de largeur `Base.Size.X/Z < 318`, contre **22** juste avant les trois derniers correctifs. Ces 19 cas demandent une analyse *par contrat géométrique* : plusieurs sont associés à des routes ou sols qui doivent suivre la dalle, et ne doivent surtout pas être convertis aveuglément.
- **Pas encore certifié :** suite Roblox Engine du commit final, captation des cinq arènes en Low/Medium/High, FPS Android et publication de la version publique Roblox. Ne pas affirmer que la correction est visible dans le jeu public sans cette preuve.

## Suite prioritaire

1. Classer les 19 kits restants entre décor fixe et plateforme réelle qui change de géométrie lors de la contraction.
2. Traiter en priorité les monuments Classic/Crossroads et les signatures sud non physiques, en réutilisant strictement les MeshParts approuvés existants.
3. Réexécuter les tests Roblox Open Cloud Engine sur le nouveau commit, puis capturer la scène sur Android Low et mesurer la résidence 3D, l'absence de trous et les FPS.
4. Publier uniquement une fois les validations moteur et la provenance des assets contrôlées, sans prétendre avoir effectué une publication que les Actions ne prouvent pas.
