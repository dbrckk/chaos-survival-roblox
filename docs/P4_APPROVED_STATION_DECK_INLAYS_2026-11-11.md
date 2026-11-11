# P4 — Socle de station sculpté et six signaux protégés

11 novembre 2026. Base du développement : `d243e009` (GitHub).
Ce changement ne publie pas automatiquement la Place Roblox.

## Audit réel

La station périphérique générée par `MapBuilder.lua` possède
23 composants visuels non physiques. Les six formes sans substitution
3D qu'il ne faut pas aveuglément masquer sont :
`LeftLightNotch`, `RightLightNotch`, `CoreLens`,
`WayfindingInset`, `PodDataRailL`, `PodDataRailR`.
Elles servent d'éclairage, de lecture de matière, d'identification
ou d'orientation ; **elles restent dans leur état original**.

La septième forme est un grand rectangle plat décoratif :
`InlaidStationBase`, 12×0,07×11 studs. Elle est maintenant éligible
à un vrai remplacement 3D avec un insert sculpté.

## Original 3D approuvé réutilisé

Le nouveau module client
`ApprovedPerimeterStationDeckInlayMeshKit.lua` partage la même
source vérifiée que le sol premium : `PremiumRouteMeshTemplates/
PremiumGroundTile`, asset Roblox propriétaire Approved
`72507987666671`, **exactement sept MeshParts**, authentiques
normales, UV et matériaux industriels.

Un insert de **8,2×8,2 studs** est redimensionné uniformément
dans le socle, décollé de 0,9 stud vers l'arrière pour laisser
visible l'indicateur `WayfindingInset` situé côté avant.
La position suit la vraie base native ; cette source miniature
reste sans collision, contact, requête ni ombre dynamique.
La transparence native ne change qu'après la validation des sept
MeshParts et du montage. Aucun autre signal ni surface de jeu
n'est modifié.

| Tier | Socles 3D maxi | Portée | Pression 1/2 |
| --- | ---: | ---: | --- |
| Low | 1 (7 MeshParts) | 95 studs | 0 / 0 |
| Medium | 2 (14 MeshParts) | 165 studs | 1 / 0 |
| High tactile | 2 (14 MeshParts) | 225 studs | 1 / 0 |
| High PC | 4 (28 MeshParts) | 225 studs | 2 / 0 |

Le module réutilise la passe caméra existante de
`scenery-lod.client.lua`, et son dossier
`ApprovedPerimeterStationDeckInlaysLocal` est inscrit au census
Android existant. Perte de source, streaming incomplet, déplacement,
Shrinking Arena ou pression graphique : le socle plat natif revient
automatiquement, même s'il avait été brièvement retiré de l'arbre.

**Couverture source potentielle : 17/23 pièces (73,91 %)**, contre
16/23 avant, pour cette seule famille de stations. Ce n'est ni une
proportion du jeu entier ni une mesure de la visibilité réellement
obtenue en cours de partie.

Le test source préexistant
`tools/verify_original_3d_budget_census.py` contrôle la propriété
de la source, le montant des MeshParts, le repli et les six éléments
restés intacts. Les autres CI de régression continuent de s'exécuter.
Cela ne remplace pas un contrôle rendu/FPS Android ni les tests
Roblox Engine sur le SHA exact avant publication.
