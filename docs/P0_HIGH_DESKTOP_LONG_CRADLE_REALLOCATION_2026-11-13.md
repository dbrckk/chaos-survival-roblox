# Chaos Survival — P0 : huit grandes structures 3D High PC sans augmentation de budget

**Dépôt** `dbrckk/chaos-survival-roblox`, branche `main`. **Date** : 13 novembre 2026.

## Problème et géométrie authentique

Le recensement initial du moteur répertorie **520 sous-cadres primitifs `PlatformUnderFrameN` dans les cinq définitions** (pas 520 présents dans une seule session). Ils sont conservés côté serveur comme repli sans collision. L'asset existant **`LongCradle` `128914328933863`**, créateur/modération approuvés et modèle sculpté de sept MeshParts, peut recouvrir plusieurs vraies plateformes des promenades de chaque arène. Avant le correctif, seules quatre plateformes pouvaient recevoir ce châssis en High, même sur PC puissant. Une partie du budget de 16 modules déjà alloué aux supports était dépensée à habiller de petits piliers plutôt que de remplacer les grandes masses rectangulaires des sous-cadres.

## Allocation réelle : mêmes 20 modèles de sept MeshParts maximum

| Type de client / tier | Sous-cadres `LongCradle` | Colonnes `PlatformSupport` | Total combiné |
|:--|--:|--:|--:|
| Low (mobile/PC) | 1 au maximum (exclusivité existante avec les supports) | 1 au maximum (exclusivité existante) | **1**, pas 2 |
| Medium | 2 | 8 | **10** |
| High Android/tactile | 4 | 16 | **20** |
| High PC non tactile, ≥8 sous-cadres compatibles | **8** | **12** | **20** |
| High PC, moins de huit candidats | 4 à 7 | 16 à 13 | **20** |

Les nombres sont des **plafonds de modèles 3D source** et non des garanties de présence à l'écran. Le client ne réalloue des ressources que si des plateformes *réellement construites*, sûres et **compatibles avec les dimensions de la vraie source `LongCradle`** sont présentes. Si l'asset n'est pas importé ou qu'aucune plateforme ne convient, les quatre emplacements originaux de sous-cadres sont conservés et la limite de supports reste à 16.

Le calcul a été centralisé dans `PremiumLargeStructureMeshKit.desktopCradleTransfer()` : quatre transferts au maximum, strictement sur **High non tactile**. `arena-platform-identity.client.lua` alloue `4+transferred` LongCradles et `16-transferred` supports. Les MeshParts réels, les collisions, les limites locales Android et le chargement approuvé ne changent pas. Les signes de catastrophe et les sous-cadres primitifs réapparaissent en cas de source perdue, de streaming/collapse ou de montage invalide.

## Vérifications

- Les registres/source approuvés sont inchangés. Aucun asset Marketplace, fausse géométrie ni suppression de collision.
- `tools/verify_platform_trim_mesh_ownership.py` vérifie les limites 4/8, la distinction non tactile et les **20 modules constants** ; [dernier résultat source vert](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43418848693).
- `tests/engine/native-premium-fallback.spec.luau` construit la **vraie arène Crossroads**, vérifie les limites sur les vrais sous-cadres compatibles, un montage réel avec MeshParts de fixture (pas des assets de production), le signal `CollapsePhase=Warning`, la conservation des colliders et le repli des natives. Le test actuel est renforcé pour monter les huit propriétaires High.

**Non vérifié par ces tests** : FPS Android/PC réels, images finales, taux de couverture réellement perçu dans le jeu public, publication Roblox. Aucun compte total « définitivement remplacé » ne peut être déduit du seul recensement serveur.
