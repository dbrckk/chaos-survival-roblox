# Chaos Survival — P0 : recensement réel des 16 districts et complémentarité 3D bilatérale

Date : 13 novembre 2026. Dépôt : `dbrckk/chaos-survival-roblox`. Branche : `main`.

## Portée réelle

Il existe **16 bâtiments serveur par variante d'arène** (4 North, 4 East, 4 South, 4 West), soit **80 définitions de bâtiments dans cinq variantes** ; ils ne coexistent pas tous en une partie. La scène client peut n'en répliquer qu'une partie à cause de `ModelStreamingMode.Atomic`. Les compteurs globaux du nombre de primitives générées ne prouvent pas quels bâtiments affichent réellement leur vraie sculpture.

Le client possède déjà deux familles `MeshPart` de créateur modéré `Approved` :
- Façades et rooflines des quatre profils, via `PremiumDistrictFacadeMeshKit.lua`, qui remplacent les volumes de façade/toit réellement présents.
- Coque arrière/latérale `77387019170428`, six vrais `MeshPart` / 1 764 triangles, via `ApprovedDistrictSidewallMeshKit.lua`, qui masque précisément cinq natives non physiques, en conservant porte, fondation et gameplay.

## Correction de la couverture visuelle

En Medium et High, un bâtiment peut avoir un arrière sculpté sans façade. Le propriétaire `ApprovedDistrictSidewallMeshKit` publie dorénavant son **attribut local de résidence** `LocalApprovedDistrictSidewallMounted=true` uniquement après validation de ses six MeshParts et de ses cinq natives. La disparition du modèle, la perte des parties source, un changement d'arène, le streaming ou un plafond GPU effacent l'attribut **au moment du repli**, sans boucle supplémentaire.

Le kit de façades attribue maintenant un bonus de rang **équivalent à 12 studs** aux bâtiments dont la coque approuvée est déjà présente (Medium et High seulement). Cette priorité inverse complète le bonus de 16 studs déjà utilisé côté coque lorsqu'une façade authentique est présente. Les préférences ne remplacent ni la priorité caméra ni la pénalité hors champ de 80 studs. **Low demeure strict : sa seule coque 3D exige toujours une façade réelle déjà montée.**

Aucun nouveau modèle, import, `RenderStepped`, `Heartbeat`, collider ni volume GPU n'est créé. Budgets latéraux : Low 1, Medium 4 (tactile 3), High 10 (tactile 8). Les native Parts non physiques sont restaurées quand la vraie source 3D n'est plus disponible.

## Inventaire de résidence par bâtiment — fiable malgré le streaming

Pour éviter de confondre **un objet non chargé** avec **une forme primitive qui reste à upgrader**, un module pur `src/shared/DistrictVisualCensusRules.lua` agrège trois masques 16 bits : le masque des vrais bâtiments serveur répliqués et les deux masques d'instances 3D réellement montées et vérifiées. Chaque position `1..16` suit l'ordre du générateur serveur (North 1..4, East 5..8, South 9..12, West 13..16).

L'attribut local `LocalDistrict3DStates16` contient exactement 16 caractères :
- `B` : **both** — vraie façade et vraie coque latérale sur le même bâtiment.
- `F` : modèle façade seul.
- `S` : modèle latéral seul.
- `N` : bâtiment réel **chargé** sans modèle 3D approuvé de ces deux familles.
- `-` : bâtiment **non répliqué**. Ne jamais le classer comme restant primitif.

Attributs complémentaires : `LocalDistrict3DLoadedCount`, `LocalDistrict3DUnstreamedCount`, `LocalDistrict3DNativeOnlyCount`, `LocalDistrict3DFacadeOnlyCount`, `LocalDistrict3DSidewallOnlyCount`. Ils s'ajoutent à `LocalCompleteDistrict3DCount` et au compteur réel de natives remplacées. Le total `loaded + unstreamed` vaut **16**, et `nativeOnly + facadeOnly + sidewallOnly + complete` vaut `loaded`.

**Limite importante** : `N` indique l'absence de ces deux modèles MeshParts **à cet instant sur ce client**, pas nécessairement un élément réellement visible dans le champ de la caméra. Les bâtiments ignorés par les règles LOD natives peuvent rester invisibles. Cet inventaire n'est donc pas un « pourcentage d'AAA terminé », et une seule session ne couvre pas les cinq mondes.

## Tests et conditions de publication

- `tools/verify_original_3d_budget_census.py` : source approuvée, limites mobile, ordre façade → coque, présence des attributs/masques, règles 16 états, restauration à l'éviction.
- `tests/engine/visual-budget-rules.spec.luau` : le **vrai générateur serveur à 16 bâtiments** ; exige la façade et les six MeshParts avant de masquer les cinq natives, contrôle le bit de résidence et sa disparition immédiate sous pression GPU.
- `tests/engine/native-premium-fallback.spec.luau` : priorités Low/Medium/High et cas limites des masques (présents, partiels, non répliqués), en plus des tests réels de remplacement des infrastructures. Les fixtures sont réservées aux tests ; aucune n'est incorporée au jeu livré.
- Le fichier `visual-budget-rules.spec.luau` reste sous le plafond strict de 105 000 octets des tâches Roblox Open Cloud.

L'exécution du test moteur ne valide pas les FPS ni le rendu visuel réel sur Android et ne publie pas le Place Roblox public.
