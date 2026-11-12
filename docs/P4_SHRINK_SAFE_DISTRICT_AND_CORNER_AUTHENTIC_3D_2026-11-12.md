# P4 — Conserver les façades et les tours d'angle 3D pendant le rétrécissement

**12 novembre 2026 — régression de rendu vérifiée dans le code, corrigée côté client.**

## Problème

`MapBuilder.lua` crée une base de **320 studs** et sérialise sa
taille immuable dans `OriginalSizeX` / `OriginalSizeZ`.
Pendant les manches, la surface jouable se rétrécit. Les
**16 bâtiments de quartier** et **4 monuments d'angle** sont pourtant
des décors non physiques dont les positions ne suivent **pas** cette
réduction de largeur.

Les deux kits 3D authentifiés :
- `PremiumDistrictFacadeMeshKit.lua` ;
- `ApprovedCornerMonumentMeshKit.lua` ;

exigeaient néanmoins `base.Size.X/Z >= 318` à chaque synchronisation,
y compris lors de la vérification des modèles déjà montés. Au premier
rétrécissement notable de l'arène, les véritables sculptures originales
étaient donc démontées et les pièces primitives natives redevenaient
visibles, même à proximité du joueur en Medium/High.

## Correction réelle

Les deux propriétaires utilisent désormais une vérification
`authenticBase(base, arena)` fondée sur :

1. une `BasePart` ancrée et collisionnelle, appartenant exactement à
   l'arène courante ;
2. `OriginalSizeX` / `OriginalSizeZ` réellement enregistrés par
   le `MapBuilder`, chacun d'au moins 318 studs ;
3. une largeur/longueur **actuelle** strictement positive et **ne
   dépassant pas** la dimension originale (tolérance 0,2 stud).

Cette vérification est réutilisée pour le montage, la validation
continue et le callback existant sur `Base.Size`.
**Le rétrécissement normal n'est plus considéré comme une corruption
du décor.**

L'effacement reste immédiat à la prochaine vérification si
la base n'est plus celle de l'arène, si ses dimensions originales ne
sont plus valides ou si elle n'est plus physique/ancrée.
L'éviction par la caméra, le streaming, l'indisponibilité du
Model approuvé et les transformations d'ancrage de porte/plinthe
restaurent toujours les formes natives.

## Périmètre et budgets préservés

| Groupe 3D | Low | Medium | High | Remplacement visuel |
| --- | ---: | ---: | ---: | --- |
| Façades des 16 bâtiments | 1 | 5 | 12 | Toitures, rails, profiles 3D approuvés |
| 4 monuments d'angle | 1 | 4 | 4 | Tours/antennes et structures originales |

Le tableau décrit les **plafonds de modèles candidats**,
pas la quantité garantie à l'écran : caméra, streaming,
source chargée et espace de rendu restent déterminants.

Aucun nouvel asset, texture, requête Roblox, shader,
Part, lumière ou mouvement. Les MeshParts restent `Anchored`,
`CanCollide=false`, `CanTouch=false`, `CanQuery=false`,
`CastShadow=false`. Les vraies structures jouables,
portes, fondations et les signaux de navigation ne sont pas remplacés.

## Contrats et validation

Le vérificateur source déjà existant
`tools/verify_original_3d_budget_census.py` contrôle les deux kits,
le référencement des valeurs originales du MapBuilder, les gardes
de provenance, le maintien des budgets et des chemins de restauration.
Il s'exécute dans
`original-3d-budget-census-regression.yml`.

**Limite :** les vérifications source ne mesurent ni des captures Roblox
Studio, ni le nombre effectivement résident pendant une catastrophe
sur Android, ni les FPS, ni une publication.
Avant certification, comparer captures et compteurs
`LocalOriginalDistrictFacadeMeshCount`,
`LocalOriginalCornerMonumentCount` et
`LocalOriginalDistrictRooflinesReplaced` avant/après shrink sur
les cinq arènes en Low/Medium/High, avec contrôle de collisions et
retour natif après streaming/LOD.
