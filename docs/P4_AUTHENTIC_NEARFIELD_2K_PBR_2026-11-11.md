# P4 — Véritables textures PBR sur les sculptures 3D proches

**11 novembre 2026**. Le lot corrige une limite concrète des modèles originaux
7-groupes qui utilisaient des facteurs de métal/rugosité constants : ils
possédaient des silhouettes détaillées mais pas de `normal/roughness/`
`metalness` d'image au voisinage de la caméra.

## Implémentation

`src/client/PremiumNearfieldPbrKit.lua` réutilise les **16 mêmes images**
déjà approuvées pour les quatre `SurfaceAppearance` de
`OriginalGroundPbrTemplates` dans `default.project.json` :

- `DiamondArmor` : pièces ARMOR d'origine, sauf Crossroads acier oxydé ;
- `BrushedTitanium` : BRUSHED et ALLOY ;
- `ReactorCeramic` : CERAMIC ;
- `OxidizedSteel` : ARMOR Crossroads.

Les groupes **SIGNAL, CARBON, GRIP, GLASS** restent inchangés pour
préserver la lisibilité des signaux, des grips et des volumes sombres.

Seuls les clones `Model` vérifiés et conservés par leurs kits peuvent
recevoir ces textures ; le contrôleur vérifie à chaque passage
le dossier propriétaire, `CosmeticOnly`, l'ID Roblox approuvé et
**sept MeshParts non-collidables**. Le modèle doit être à moins de
175 studs en Medium et 245 en High. Il ne couvre pas des modèles
tiers ni des meshes de gameplay.

Il utilise le passage déjà exécuté dans
`src/client/scenery-lod.client.lua`, après les mises à jour des six
familles : ailerons Classic, mâts Classic/Towers, machines Towers,
portails Crossroads, portiques Crossroads et réacteurs Orbital.
Pas de nouvelle boucle, aucun `RemoteEvent`, ni nouvelle image
requérant upload/crédit.

## Budget et restauration

| Qualité | Android | PC |
|---|---:|---:|
| Low | 0 | 0 |
| Medium | 2 modèles | 3 modèles |
| High | 4 modèles | 6 modèles |
| Pression 1 | 1 Medium / 2 High | 1 Medium / 3 High |
| Pression 2, opt-out PBR | 0 | 0 |

Le budget compte des **modèles entiers de sept groupes**, pas des
textures supplémentaires de 2K ; tous réutilisent les mêmes quatre
sources d'images. Aucune hausse du nombre de modèles visibles, des
imports Roblox ni de la géométrie. Le contrôleur choisit les sources
authentiques les plus proches.

Lorsqu'un modèle quitte la vue, est détaché par son propriétaire,
subit une baisse de qualité ou quand PBR est désactivé, les
`SurfaceAppearance` ajoutées sont détruites, les apparences
originales glTF restaurées sans écraser un autre auteur. En cas
d'erreur sur un seul élément, la tentative entière est annulée.
Le module publie uniquement deux compteurs locaux :
`LocalPremiumNearfieldPbrModelCount` et
`LocalPremiumNearfieldPbrSurfaceCount`.

## Vérifications et limites

Le test source `tools/verify_premium_nearfield_pbr.py` contrôle
les huit références d'assets couvrant les six familles, les
seize cartes approuvées, les restrictions de sécurité, la prise
en compte du LOD et la restauration. La suite moteur existante
`arena-material-rules.spec.luau` teste les budgets et les groupes
dont les matériaux doivent être préservés.

**Limites :** ce lot n'est pas une nouvelle texture unique par
arène, ne certifie pas des FPS Android ou une capture, ne modifie
pas les modèles approuvés eux-mêmes et ne publie pas le Place
Roblox. La véritable qualité des nouvelles normales/roughness doit
être examinée dans Studio et sur appareil après une publication
validée et réversible.
