# P4 — Remplacement des piliers et silhouettes atmosphériques natives

11 novembre 2026. Source : `src/server/ArenaAtmosphere.server.lua` génère
quatre `AtmospherePillar1..4` autour des joueurs et quatre
`SilhouetteSpine1..4` aux coins de chacune des cinq variantes.
Il existe **8 corps primitifs par variante, 40 occurrences de définition**
sur cinq variantes, et une seule variante est active par manche. Les deux
familles sont non-collisionnelles et exclusivement décoratives.

## Modification réalisée

`src/client/ApprovedAtmosphereColumnsMeshKit.lua` monte, quand la
source est déjà présente, des clones des colonnes réelles et modérées du
créateur (sept MeshParts par sculpture). Il n'utilise que les cinq
sources existantes du dossier `ApprovedLargeStructureTemplates` :

| Arène | ID de modèle Roblox approuvé |
| --- | --- |
| Classic | `91626128452597` |
| Towers | `107521411452905` |
| Crossroads | `93993697329658` |
| Orbital | `119010829781313` |
| Harbor | `76194593490199` |

Les sources sont vérifiées par `OwnerVerified`, `CosmeticOnly`,
`OriginalLargeStructure3D`, leur ID connu, leur géométrie réelle
et leurs sept MeshParts non-collidables. Les cibles sont validées
contre la vraie carte, son identifiant de variante, `VisualVersion=2`,
la position, la taille, le type de primitive et les balises
spécifiques : `AtmosphereBeacon`, `SilhouetteCap` et
`SilhouetteBand`. Les signaux ne sont ni masqués ni remplacés.

Le modèle est uniformément mis à l'échelle sans écraser sa silhouette ;
les colonnes trop larges, notamment certaines tours hautes, sont
**volontairement refusées** plutôt que déformées ou placées à travers
les signaux. Ce n'est donc pas une promesse de substitution de 8/8
dans un rendu particulier.

Une sculpture est clonée, intégralement vérifiée et montée **avant**
de cacher son corps natif. Les collisions, la physique des catastrophes,
les balises de guidage, les couleurs des signaux et la carte serveur
ne changent pas. En cas de perte de source, streaming incomplet,
suppression du clone, changement de carte ou baisse de qualité, le
corps primitif est restauré et le clone retiré.

## Limites graphiques et ressources

| Profil | Sculptures simultanées |
| --- | ---: |
| Low Android/PC | 0 |
| Medium Android/PC | 2 |
| High Android | 3 |
| High PC | 4 |
| Pression 1 | moitié du quota arrondie vers zéro |
| Pression 2 | 0 |

Les modèles sont choisis par proximité caméra (230 studs Medium,
390 studs High), avec petite rétention pour éviter le clignotement.
Au maximum **28 MeshParts** supplémentaires sont rendus par le kit.
Chaque sculpture montée remplace **un** seul corps natif : compteur
`LocalAtmospherePrimitiveColumnsReplaced`, à distinguer du
nombre de pièces 3D `LocalAtmosphereApprovedColumnCount`.

Le kit réutilise strictement `scenery-lod.client.lua` :
pas de nouvelle boucle, pas de client AssetService, pas de nouvelle
Texture/Model Roblox, pas d'événement distant. Le serveur
`PremiumLargeStructureAssets` garde les **six sources d'origine**,
les trois tentatives et la file globale de deux demandes au maximum,
mais démarre désormais à 29 s au lieu de 35 et trie d'abord le
modèle de l'arène active. Les temps de requêtes et la présence
des modèles pendant la première manche restent incertains.

## État de validation

Changements consignés dans la PR #809, sans merge ni publication du
jeu public à ce stade. La relecture GitHub du diff ne prouve pas que
les MeshParts sont visibles en jeu ni que l'éclairage sera esthétiquement
adapté. Au jalon de sortie, il faudra vérifier dans Roblox Engine et
sur Android Medium/High la silhouette, le fallback sous pression,
les FPS et le rendu des signaux après rotation de carte. Les couronnes,
anneaux lumineux, guides et noyau Orbital restent volontairement natifs :
ce sont des éléments de lecture de gameplay, pas encore des modèles 3D.

**Le nombre 40 est un inventaire de définitions sur les cinq
variantes, pas un nombre de formes remplacées à l'écran et pas un
pourcentage de couverture globale du jeu.**
