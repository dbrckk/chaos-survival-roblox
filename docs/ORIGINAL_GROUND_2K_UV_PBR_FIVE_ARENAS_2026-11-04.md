# Chaos Survival — vrais PBR 2K sur les UV des meshes 3D du sol (4 novembre 2026)

**Statut : candidat source sur `main`, pas une publication publique ni une certification du rendu Android.**

## Problème visuel résolu

Le kit `PremiumGroundMeshKit` peut déjà couvrir les **36/36 dalles physiques** de 49 studs sur High avec les 3D originales `72507987666671` (2 976 triangles source par dalle, jusqu'à 7 MeshParts par asset). Ces modèles possèdent de vrais `TEXCOORD_0` et `TANGENT` produits par `tools/obj_to_gltf.py` : les **textures Color/Normal/Roughness/Metalness** n'étaient pourtant **pas appliquées directement à ces UV**.

Le `MaterialVariant` 2K existant ne s'appliquait qu'à certaines anciennes surfaces natives sous les meshes. Cela consommait inutilement le budget 2K sans rendre le relief PBR sur la vraie sculpture 3D visible.

## Travail effectué

1. **Vraies données textures :** le `default.project.json` sérialise maintenant quatre instances `SurfaceAppearance` dans `ReplicatedStorage.OriginalGroundPbrTemplates` avec **16 vrais IDs Image** Roblox, provenant des quatre palettes de 2K originales approuvées en audit le 28 octobre (même propriétaire, contrôle de modération et état à la date du contrôle, [preuve #40682190586](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/40682190586)). Aucun nouvel asset ID fabriqué ou upload inutile.
2. **Application directement sur la sculpture :** `src/client/PremiumGroundPbrKit.lua` clone uniquement ces `SurfaceAppearance` préconfigurés sur des `MeshPart` appartenant à l'asset original `72507987666671` authentifié et monté par le kit existant. Il ne tente **jamais** d'écrire des propriétés `ColorMap`, `NormalMap`, `RoughnessMap`, `MetalnessMap` depuis un script : ces propriétés Roblox nécessitent une autorisation de plugin (la sérialisation Rojo établit les valeurs).
3. **Cinq identités de surfaces :** Classic = armure antidérapante, Towers = titane brossé, Crossroads = acier oxydé routier, Orbital = céramique technique, Harbor = acier marin oxydé. Les segments explicitement nommés `BRUSHED`/`ALLOY` ou `CERAMIC` conservent leur famille spécifique ; les sous-segments `CARBON`, `GRIP` et `SIGNAL` restent sans surcouche pour préserver le contraste original. Si Roblox ne préserve pas le nom de matériau, une famille dominante cohérente par arène est utilisée.
4. **Une seule vraie ressource par rôle :** lorsqu'une dalle `PremiumGroundModuleN` est réellement recouverte par sa sculpture approuvée, le marqueur client local `LocalApproved3DGroundResident` exclut le panneau sous-jacent du sélecteur global `PbrDistrictRules`. Le budget original 2K de 32/72 surfaces Android peut servir aux véritables plateformes/parois au lieu de payer pour un sous-plancher occulté. Le marqueur disparaît lors d'un démontage, d'une catastrophe ou d'un modèle manquant.
5. **Vrai repli au streaming :** si une `MeshPart` source disparaît, le kit restaure immédiatement les traces natives cachées, supprime ses surcouches PBR et retire le marqueur de résidence. Les autres couches du sol restent intactes. Si le package apporte déjà son propre `SurfaceAppearance` sans les quatre cartes 2K, l'ancien objet reste intact et sera restauré après la surcouche ; aucun écrasement permanent ni doublon actif.
6. **Gestion des SurfaceAppearance originaux importés :** un import glTF peut créer lui-même un `SurfaceAppearance` pour les seuls facteurs matériaux. Le propriétaire source `72507987666671` conserve cette instance dans une table locale au moment du remplacement par les vraies quatre maps 2K, puis la **remet en place à l'identique** au prochain démontage, changement de tier ou recul de pression. Il n'est jamais nécessaire d'écrire une propriété Roblox protégée, ni de détruire définitivement l'apparence d'origine. Un test sur de vraies instances moteur `MeshPart`/`SurfaceAppearance` vérifie l'installation, la réconciliation sans doublon et le retour à l'original.
7. **Libération du budget native même caméra immobile :** le sampler PBR existant détecte désormais le marqueur `LocalApproved3DGroundResident` comme une sélection périmée : après l'arrivée tardive de l'original MeshPart, il récupère les vieux `MaterialVariant` du sous-plancher au prochain passage, sans attendre que le joueur bouge ou tourne la caméra.
8. **Diagnostic réel :** `LocalGroundPbr2KTileCount` et `LocalGroundPbr2KAppearanceCount` comptent les instances effectivement montées ; ces valeurs ne prétendent ni mesurer la mémoire GPU ni prouver qu'une texture est lisible sur un Android spécifique.

## Budgets / ralentissements

| Qualité | Sans pression | Pression FPS 1 | Pression FPS 2 |
|---|---:|---:|---:|
| Android Low | 0 | 0 | 0 |
| Android Medium | 2 dalles UV PBR | 1 | 0 |
| Android High | 6 dalles UV PBR | 3 | 1 |
| PC Medium | 4 | 1 | 0 |
| PC High | 12 | 6 | 1 |

Une dalle PBR possède au plus sept SurfaceAppearance ; même à **High Android normal**, cette surcouche concerne donc **au plus 42** enfants 3D, réutilisant les 16 images sources au maximum. Les meshes eux-mêmes conservent leur résidence 2/12/36 au repos et leurs plafonds adaptatifs précédents. Les 2K réels nécessitent un **contrôle GPU / mémoire et FPS sur Android** avant publication ; le nombre de SurfaceAppearance n'est pas une métrique de VRAM.

Les contrôleurs de relief, sécurité, météo, danger et lumière ne sont pas remplacés. `PremiumGroundMeshKit` réutilise la **boucle caméra LOD existante** : aucun nouvel `RunService`, timer, `RemoteEvent`, lumière, émetteur ou collider. `PbrMaterialsDisabled` retire immédiatement les copies au prochain cycle LOD sans modifier la qualité de jeu.

## Acceptation obligatoire

- Build Rojo et lint source sur le commit exact ; la CI doit comparer chaque ID PBR sérialisé aux 16 approbations de l'audit, interdire toute écriture runtime vers une map protégée et garder les limites Android.
- Sept suites réelles Roblox Cloud, avec contrôles du budget `tileBudget`, des cinq finitions, du refus des modèles inconnus.
- Vérification visuelle Roblox Studio / Android High, Medium, Low avec captures réelles : présence des reliefs normaux 2K dans les dalles 3D visibles, contraste des marquages de catastrophe, front/back face et raccords UV, dix minutes de stress FPS.
- Contrôle StreamingEnabled, `ShrinkingArena`, bascule des arènes et réapparition des dalles natives à la perte de mesh.
- **Pas de publication publique tant que ces validations de rendu et de performance ne sont pas terminées.**
