# Tower Run — 5 grandes installations thermiques 3D authentiques, deux silhouettes originales

**4 novembre 2026. Source `main`, sans publication du jeu.** Deux vrais modèles glTF importés au propriétaire Roblox du jeu, avec modération **Approved**. Aucun identifiant Roblox inventé.

## Défaut visuel constaté dans le dépôt

Le constructeur natif `src/client/arena-midground-mass.client.lua::buildTowers` affiche jusqu'à **cinq pylônes de refroidissement en `Part` parallélépipédiques** : hauteurs 34 / 44 / 30 / 38 / 27 studs, largeurs 9 / 10 / 8 / 9 / 7. Ils sont hors de l'arène physique et portent des ornements `ArenaDetailKit` (vents, bandeaux, outils), eux aussi primitifs. Plusieurs simples blocs carrés rendaient la silhouette industrielle de Tower Run moins travaillée que Storm Harbor.

Les cinq `TowerCoolingMass[1..5]` d'origine **restent présents** : le jeu, ses collisions, ses parcours, bots, catastrophes et cartes ne sont pas modifiés.

## Deux assets premium réellement fabriqués et approuvés

| Modèle | ID Roblox propriétaire | Géométrie originale vérifiée | Source et workflow |
|---|---|---|---|
| **Grande tour à turbine** | `95543769387033` | **6 380 triangles**, 148 groupes 3D, cheminée structurée, double régulation sous pression, anneaux de turbine et vingt-quatre canaux de renfort | `tools/generate_original_towers_cooling_spire.py` · [#41904066937](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904066937) |
| **Tour à ventilation creuse** | `97498534364335` | **9 980 triangles**, 330 groupes 3D, coque hyperboloïde à **double paroi intérieure réelle**, ouverture d'extraction supérieure, bandes forgées, échelle de service, chambres de ventilation et canalisations | `tools/generate_original_towers_cooling_stack.py` · [#41904135484](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904135484) |

Les deux utilisent sept matériaux d'origine **ARMOR/BRUSHED/CARBON/GRIP/ALLOY/CERAMIC/SIGNAL** ; glTF autoportant avec vraies normales, UV et tangentes. Les deux modèles ont passé le contrôle de géométrie source et sont réellement modérés **Approved** dans les logs d'import. Dimensions source exactes :

- Turbine : **6.6444 × 29.11975 × 4.956**, auteur ratio `0.42`, corps technique de référence 40 studs et haut mât 69 studs après restauration.
- Refroidissement creux : **6.256 × 21.1646 × 5.52**, auteur ratio `0.46`, corps de référence 44 studs. L'intérieur creux est sculpté en triangles, pas simulé avec un cylindre plein.

Le registre `assets/source/roblox-asset-registry.json` contient **62 modèles propriétaires Approved** dont ces deux derniers, et `ci.yml` refuse toute dérive de provenance, d'ID ou de nombre.

## Fonctionnement réel dans Roblox

- `PremiumTowerCoolingSpireAssets.lua` et `PremiumTowersHollowStackAssets.lua` chargent seulement les deux IDs autorisés via `AssetService.LoadAssetAsync`. Les modèles distants sont nettoyés par `OriginalMeshScenery.sanitize`. Les sept MeshParts originaux sont contrôlés par leur vraie boîte englobante avant la réplication.
- `TowerCoolingSpireMeshKit.lua` sait reconnaître les cinq vrais `TowerCoolingMass[1..5]` de l'arène **Towers** et les objets affiliés déjà marqués `OriginalTowerCoolingSpireIndex` par le constructeur d'origine. Le même kit répartit **la silhouette creuse sur 1, 3 et 5**, et **la turbine sur 2 et 4**, évitant cinq clones identiques.
- Chaque sous-modèle est ancré, non collisionnant et aligné sur la base physique **du décor original**. L'échelle du grand mât préserve sa hauteur supplémentaire sans déplacer le parcours ; celle du refroidissement creux garde une silhouette plus trapue autour de la hauteur de référence.
- Le client ne masque **que les Parts natifs de la même installation** lorsque le clone approuvé possède bien ses sept vrais MeshParts. Tous les anciens détails et corps restent présents pour se rétablir à un changement de carte, un streaming incomplet, un échec source ou une baisse de qualité.
- Une seule boucle caméra, celle déjà prévue dans `scenery-lod.client.lua`, active et sélectionne les modèles selon la distance et la pression FPS ; aucune nouvelle animation, simulation physique, lumière ou RemoteEvent. Le dossier `OriginalTowerCoolingSpireLocal` compte déjà dans le budget Android commun de `VisualBudgetRules`.

| Qualité | Pression 0 | Pression 1 | Pression 2 |
|---|---:|---:|---:|
| Low | 0 | 0 | 0 |
| Medium | 2 modèles max / 14 MeshParts | 1 / 7 | 0 |
| High | 5 modèles max / 35 MeshParts | 3 / 21 | 0 |

**Source indisponible d'un seul style ?** La tour concernée conserve uniquement son natif. Les autres installations peuvent continuer à être sculptées, sans erreurs, trou visuel ni substitut fictif.

## Critères de publication encore nécessaires

1. Validation exacte du registre 62 Approved, export source, Rojo build et sept suites moteur Roblox Cloud sur **un même SHA**. Vérifier notamment le timeout du shard matrix : son précédent échec du 4 novembre avait déjà été résolu par le jalon mer `42b09df` (tous tests verts).
2. Contrôle d'images **réelles sur Android**, Tower Run High puis Medium : vérifier les cinq modèles, le vrai creux supérieur et la cheminée à turbine ; confirmer une bonne orientation des armatures et aucun reste de `Part` à travers les MeshParts.
3. Vérifier 30 minutes de FPS/mémoire, qualité Low/Medium/High, pression maximale, changement de carte, rétrécissement du sol, déconnexion et reconnexion. Aucun nouveau collider ni plateforme flottante.
4. **Aucune publication publique annoncée avant contrôle des validations et vérification visuelle du jeu.** Les workflows d'import n'ont pas publié de Place.

**Diagnostics :** `LocalOriginalTowerCoolingSpireCount` indique le nombre de modèles réels montés (0 à 5), non une certification visuelle.
