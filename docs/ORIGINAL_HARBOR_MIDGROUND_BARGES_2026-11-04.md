# Storm Harbor — quatre barges de fret sculptées 3D : intégration source et contrat de sortie

**4 novembre 2026.** Le modèle original source et le montage client sont intégrés à `main`. **Import Roblox encore en attente** : [workflow source-gated #41862430789](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41862430789). Aucun Model ID ne doit être inventé. La scène native reste le fallback à cette étape.

## Défaut réellement vérifié

`src/client/arena-midground-mass.client.lua::buildHarbor` fabrique encore **4 barges très visibles** avec un `HarborFreightBargeHull1..4` natif `Part` 28×3.5×13.2, un grand conteneur `Part` 21×7.4×8.6, plusieurs rectangles estampés et les détails `ArenaDetailKit`. Elles se trouvent autour du grand plancher de 320 studs, de sorte que les grandes grues d'origine, le cargo géant et les plateformes premium encadrent toujours des **formes de base** à moyenne distance. Le défaut vaut une amélioration visible avant des modifications de l'atmosphère globale.

Ces quatre barges sont **des décors non physiques non marchables**, hors de l'arène. Aucune modification de leurs positions, des routes, de `ShrinkingArena`, des hazard warnings ou de la détection de vide n'est autorisée.

## Original 3D

`tools/generate_original_harbor_barge.py` écrit un OBJ intégralement triangulé à coque multi-sections, pont de fret, renforts, fendages, rambardes et amarres, 6 vrais conteneurs ISO avec nervures et fixations 3D, timonerie vitrée de pilotage, radar et bande d'identification maritime. Sept matériaux source `ARMOR / BRUSHED / CARBON / GRIP / ALLOY / CERAMIC / SIGNAL` sont convertis en glTF 2.0 à UV/normales/tangentes. L'art est conçu pour une barge originale de ~28×11×13 studs directement compatible avec son ancien hull de 28×3.5×13.2, pas un cargo géant simplement réduit.

`one-time-original-harbor-midground-barge-20261104.yml` valide source, vrais triangles, dimensions, matériaux, normals/UV/tangents et intégrité du buffer glTF avant l'import propriétaire Roblox. **Modération et ID encore à confirmer**. Ce workflow ne publie jamais le jeu.

## Contrat client et conservation physique

Dans `arena-midground-mass.client.lua`, les parties visuelles de chaque barge (y compris `ArenaDetailKit`) reçoivent `OriginalHarborMidgroundBargeIndex=1..4` **uniquement à leur création**. Aucun marquage de plateforme ou de route.

`HarborMidgroundBargeMeshKit.lua` est déjà câblé à l'unique contrôleur `scenery-lod.client.lua`. Après réception d'un **vrai modèle approuvé**, un chargeur serveur doit assainir et vérifier strictement cet ID, ses 7 MeshParts et ses dimensions et n'exposer l'original que sous `ReplicatedStorage.ApprovedHarborBargeTemplates.CoastalFreightBarge`, avec une identité serveur cohérente. Sans ce chargeur, rien n'est masqué.

Le montage exige `VariantId=Harbor`, un `Base` de 318+ studs, `ArenaMidgroundMassLocal`, un vrai `HarborFreightBargeHull[1..4]` ancré et non physique, des tailles originales intactes et les 7 pièces authentiques. Il positionne la forme 3D sur chaque cadre barge (yaw de chaque mouillage), puis **masque uniquement les descendants natifs portant le même index**, jamais un joueur, ni une plateforme, ni un avertissement. Toute perte de source/pièce, tier Low, pression GPU, source non importée, map swap ou streaming restaure les anciens objets.

| Qualité Android | Pression 0 | 1 | 2 |
|---|---:|---:|---:|
| Low | 0 | 0 | 0 |
| Medium | max 2 modèles | max 1 | 0 |
| High | max 4 modèles | max 2 | 0 |

Distance caméra Medium **270** studs et High **380** studs, avec hystérésis 27/45. Un vrai barge sculpté utilisera 7 MeshParts et comptera contre **les mêmes budgets Android 440/680/900**, jamais via un budget fictif. Pas de nouveau RenderStepped, feu, sons, Light, RemoteEvent ou physique.

## QA / jalon de sortie

1. Source-gate **success** avec dimensions et `triangles` réels, puis `Approved` Roblox et ID exact vérifié dans les logs d'owner-import (actuellement en attente).
2. Ajouter le chargement serveur strict de cet ID, provenance dans `assets/source/roblox-asset-registry.json`, et mettre à jour les allowlists de `ci.yml`. Éviter les ID temporaires et les placeholders.
3. Build + 7 suites moteur au **commit final exact**, uniquement à ce jalon, pas pendant chaque édition de source.
4. Capturer depuis Android Medium/High les quatre barges : aucune coque flottante, chevauchement de vieux conteneur ni mauvaise orientation. Rejouer Low, qualité sous pression, streaming et changement de map ; vérifier l'absence de faux parcours sur l'eau.
5. Valider FPS, mémoire 30 minutes et cohérence cargo/grues/quais **avant** publication séparée.

**Statut utilisateur :** source 3D et client préintégrés ; modèle non encore approuvé, aucune publication ni mesure Android vérifiée.
