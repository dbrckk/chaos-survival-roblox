# P4 — Sommets de stations authentiques sur Android Low

**Date :** 11 novembre 2026. **Objet :** une vraie silhouette 3D
de proximité à la place d'un empilement de primitives sur les
stations périphériques des cinq variantes.

## État du code source avant modification

`src/server/MapBuilder.lua` produit quatre stations périphériques
par carte. Chacune porte exactement deux primitives décoratives
propres au thème : un mât et une couronne Towers, une antenne et
une parabole Orbital, un faisceau et un aiguillage Crossroads,
ou des éléments de relais Classic/Harbor.

Ces paires de primitives ont déjà **quatre vrais Models**
propriétaires, modérés `Approved`, construits en sept MeshParts
par modèle et validés strictement par
`ApprovedPerimeterVariantApexMeshKit.lua` :

| Arène | Asset approuvé | Nombre de primitives remplacées par station |
| --- | --- | ---: |
| Towers | `131413152501235` | 2 |
| Orbital | `131188899020391` | 2 |
| Crossroads | `134533469777794` | 2 |
| Classic et Harbor | `110237986522853` | 2 |

Le profil **Low interdisait** leur montage (0 station).

## Changement exact

Sur Low, au plus **une station réellement visible à proximité**
(dans 150 studs de la caméra, avec rétention de 16 studs lorsque
déjà montée) peut utiliser son véritable sommet source à sept
MeshParts, masquant ses **deux** éléments natifs, sous réserve de
la présence de l'asset approuvé et de la validation de l'arène.
Les profils Medium et High restent inchangés.

En cas de pression graphique de niveau 1 :
`math.floor(1 * .5) == 0`, et la paire de primitives revient.
Au niveau 2, aucune sculpture n'est autorisée. Le contrat
préexistant restitue également la paire en cas de perte d'asset,
mutation de carte/station, source invalidée, changement de tier
ou suppression du clone du dossier local.

Aucun nouveau MeshId, atlas PBR, appel `AssetService`, boucle,
événement distant, lumière, effet de particules ou collision.
Le dossier `ApprovedPerimeterVariantApexLocal` est déjà inclus
dans le budget partagé `VisualBudgetRules.LocalFolders` :
les **sept MeshParts** du modèle occupent le même quota local
440/680/900 que les autres sculptures Android.

Le PBR 2K du kit reste réservé à Medium et High, avec les
mêmes limites et les mêmes exclusions de signaux.

## Validation requise pour publication

Ce document décrit une **éligibilité conditionnelle**, pas
la preuve que le sommet s'affiche déjà dans Roblox sur Low.
L'import serveur est optionnel et peut être différé ou refusé ;
la source réelle doit se rendre disponible. La CI source
ne certifie pas la silhouette, la visibilité du signal
`SIGNAL` ou les FPS Android dans Roblox Engine.

La publication du jeu public déjà effectuée auparavant porte
sur le commit `5590cdc` : ce lot est postérieur et
nécessite une **nouvelle publication**, précédée de Build
Validation et de Roblox Open Cloud Engine Tests sur le SHA
fusionné exact.
