# Chaos Survival — correction P4 des bordures de plateformes grand format

**13 novembre 2026 · branche `main` · intégration source, non publiée dans Roblox.**

## Cause réelle

Le client possède déjà un authentique Model 3D de coque 18 studs appartenant au créateur, **asset `125929150866282`**, approuvé et répliqué par `ApprovedLargeDeckHullTemplates`. Avant cette correction, `PremiumLargeDeckHullMeshKit.physicalFit` refusait toutes les plateformes `PlatformN` avec `N>24`. En Low, la coque était en outre conditionnée à `N % 8 == 1` et les plateformes paires étaient ignorées par la boucle de montage. Des plateformes de 16,3–20 studs, pourtant compatibles, restaient des assemblages de quatre bordures natives `WedgePart` et un sous-cadre.

La solution n'est **pas** d'étirer les carapaces compactes de 11 studs sur 18–20 studs. Elles échoueraient à couvrir suffisamment la structure. Ce correctif réemploie le modèle grand format existant et n'ajoute aucun nouvel asset, shader ou élément physique.

## Correctifs livrés

- `src/client/PremiumLargeDeckHullMeshKit.lua` : indices authentiques `Platform1..512`, géométrie strictement compatible (deck 16,3–20 studs, rapport <=1,15 ; coque certifiée avec empreinte X et Z >=80 % et <=96 % du deck), **exactement sept MeshParts** dans le modèle source approuvé.
- Sélection `selectVisibleDecks` classée par distance caméra et bornée en nombre de modèles, **avec quatre bordures et un sous-cadre répliqués et non physiques obligatoires**. La source vérifiée doit être présente avant toute réservation.
- Android et PC partagent le même propriétaire visuel, les mêmes soudures sur les vrais decks, les mêmes attributs de `CollapsePhase`, la même sélection caméra et la même restauration automatique des primitives.
- Low : un seul modèle 18-stud possible, désormais sur un index quelconque y compris pair, en concurrence avec les autres familles originales du budget partagé.
- Medium/High : sélection caméra explicite, sans création illimitée de modèles quand le garde `N>24` est levé. Les consommateurs historiques n'appelant pas cette sélection conservent le garde `N<=24` dans `install`.
- `arena-platform-identity.client.lua` : déclenche le même rebuild différé lors de la pression GPU en toutes qualités. Le streaming des pièces `PlatformBevelN_Edge` / `PlatformUnderFrameN` proches peut déclencher un rattrapage groupé lorsque le groupe de cinq natives est complet, ou lorsqu'un modèle monté perd un élément natif.
- `PlatformNativeTrimReplacementKit` reste **seul propriétaire du masquage** : quatre `PlatformBevel` + `PlatformUnderFrame` sont masqués via `LocalTransparencyModifier` seulement si les sept MeshParts vérifiés sont effectivement montés et soudés au bon colliseur. Collisions et risques sont inchangés.

## Plafonds de résidence normaux

| Qualité | PC sans pression | Appareil tactile sans pression |
| --- | ---: | ---: |
| Low | 1 coque grand format partagée | 1 coque grand format partagée |
| Medium | 3 | 1 |
| High | 6 | 3 |

En pression graphique 1, Medium PC = 1, Medium tactile = 0, High PC = 3, High tactile = 1. En pression 2 : **zéro** grand format Medium/High. Aucun ajout d'une boucle `Heartbeat` / `RenderStepped`.

Au maximum, **24 bordures + 6 sous-cadres** peuvent être masqués par les six grandes coques PC High réellement installées, en complément des autres remplacements. Ces nombres sont des **plafonds conditionnels** ; ce ne sont pas des captures ou un résultat mesuré.

## Diagnostic et validation

- `LocalOriginalLargeDeckHullMountedCount` : nombre de coques grand format de sept MeshParts effectivement montées sur l'arène courante.
- `LocalBevelNativePartsReplaced` et `LocalUnderframeNativePartsReplaced` : nombre de primitives natives effectivement masquées par l'ensemble des propriétaires 3D. Le compteur grand format n'est pas à multiplier directement pour attribuer un résultat global.
- `tools/audit_visual_structure_sources.py` : vérifications statiques de l'allowlist, de l'absence du verrou `N%8`, des empreintes, du streaming, du LOD et du compteur.
- Les **12 contrôles de contrat source** effectués sur les trois fichiers modifiés ont réussi ; la suite Roblox Engine complète, les captures Android, les FPS et la publication sur la Place **ne sont pas confirmés**.

## Limites restant à traiter

Le recensement historique du générateur comporte 2 080 bordures `WedgePart` sur **cinq reconstructions distinctes**, pas 2 080 simultanément à l'écran. La majorité des decks non compatibles 18 studs ont encore leur décor natif de repli. Un remplacement total nécessitera une vraie sculpture de bordure 3D dédiée aux autres empreintes, approuvée par Roblox, et un budget mobile réaliste ; il serait incorrect de masquer ces bordures sans géométrie authentique correspondante.
