# P4 — Grandes sculptures 3D de l'horizon maintenues pendant le rétrécissement

**12 novembre 2026.** Deuxième lot de correction du même problème de visibilité que les quartiers et tours d'angle (#863). La forme de base du jeu rétrécit en manche ; **ses architectures fixes ne se déplacent pas**.

## Bug constaté dans les propriétaires 3D

Trois autres systèmes, pourtant équipés de MeshParts originales créateur approuvées, continuaient de vérifier `base.Size.X/Z >= 318` **pendant la manche**, ou recalculaient l'emplacement de modèles éloignés avec la taille en train de rétrécir :

- `ApprovedHeroStructureMeshKit` : **1 monument hero par variante** (5 identités, une seule active), avec remplacement 3D source à distance caméra contrôlée ;
- `ApprovedPrimarySkylineMeshKit` : **4 grandes tours d'horizon** par variante, dont les corps `StructuralCore`, `TopCap` et `OuterRibL/R` sont remplacés par de vrais modèles 3D ;
- `ApprovedSkylineDepthMeshKit` : **8 toitures d'horizon** par variante avec remplacement d'authentiques `DistantRoofMass` en maillages, sans modifier les repères `DistantAerial`.

Effet : les sculptures pouvaient être démontées en quelques instants et les Parts/WedgeParts de secours réapparaître malgré des modèles correctement chargés, au pire moment de la manche.

## Correction appliquée

Les trois kits vérifient désormais que la `Base` est l'élément ancré/collisionnel **de l'arène courante**, avec `OriginalSizeX/Z` réellement inscrits par `MapBuilder` (>=318), taille actuelle positive et restant inférieure ou égale à la taille originale (0,2 stud de tolérance).

Les formules d'implantation source sont calculées avec **`originalX`, `originalZ`**, et non plus `base.Size.X/Z`. Ainsi :
- la vérification de la marge de sécurité du hero extérieur utilise l'ancien rebord, jamais le plancher déjà diminué ;
- les quatre silhouettes des tours sont validées contre leurs positions réellement créées par le builder ;
- les huit volumes d'horizon restent ancrés dans l'espace d'origine et ne sont pas faussement rejetés au prochain LOD.

La vérification des IDs Roblox, des sources `OwnerVerified`, du nombre et de la topologie des MeshParts, des vrais propriétaires `GeneratedMap`, des repères lumineux et des colis non physiques reste en place.

## Budget et sûreté

Aucun nouvel asset, aucun nouveau `Instance`, aucune texture PBR, aucune lumière, aucune collision, aucun script de rendu supplémentaire. Les budgets existants et l'adaptation à la pression GPU continuent de retirer la 3D facultative lorsqu'elle sort réellement du LOD. Les Parts natives restent en place et sont restaurées en cas d'indisponibilité d'une source, de streaming, de corruption de position, d'arène remplacée ou de pression graphique.

**Ne pas confondre couverture source et résidence réelle** : ces changements rendent les familles éligibles à conserver leurs vraies sculptures durant le shrink. Ils ne garantissent pas que les 1+4+8 candidats soient visibles simultanément, ni qu'une image rende en qualité AAA sans capture authentique.

## Contrôles

- `tools/verify_primary_skyline_3d.py` : provenance, quatre tours et coordonnées de l'ancien rebord ;
- `tools/verify_skyline_depth_approved_fallback.py` : provenance, huit toitures et coordonnées fixes ;
- `tools/verify_original_3d_budget_census.py` : vérification transversale des trois propriétaires et des plafonds visuels.

**Validation restante :** captures Roblox Engine dans les cinq univers graphiques à 320/260/200/120/60 studs de Base, sur Android Low/Medium/High et PC, avec comparaison des compteurs `LocalApprovedHeroStructure3DCount`, `LocalPrimarySkylineMeshCount`, `LocalApprovedSkylineDepthModelCount`, relevés de FPS/p95, source en streaming et restitution du décor natif.

Un contrôle source réussi n'est **ni un test Roblox Studio réel, ni un déploiement dans la Place publique**.
