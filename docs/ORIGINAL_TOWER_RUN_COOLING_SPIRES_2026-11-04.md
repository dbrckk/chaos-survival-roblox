# Tower Run — cinq installations originales 3D avec deux silhouettes de refroidissement complémentaires

**4 novembre 2026.** Source et runtime de Tower Run intégrés à `main`. Deux authentiques Roblox Models créateur **Approved** : turbine `95543769387033` ([import #41904066937](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904066937)) et véritable tour de refroidissement creuse `97498534364335` ([import #41904135484](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904135484)). Ce dossier ne représente PAS un déploiement du jeu public ni une preuve de rendu sur un véritable Android.

## Défaut d'origine constaté

Dans `src/client/arena-midground-mass.client.lua::buildTowers`, l'ancienne silhouette industrielle utilisait **jusqu'à cinq très hauts `Part` rectangulaires** `TowerCoolingMass1..5` avec quelques lignes de matériaux et trois motifs `ArenaDetailKit`. Dimensions de leurs masses : hauteurs **34, 44, 30, 38 et 27 studs**, largeurs **9, 10, 8, 9 et 7**. Ce sont des **masses non physiques hors de la zone jouable**. Les éclairer davantage ne résoudrait pas l'absence de vraie architecture.

## Original sculpté et propriétaire approuvé

Le générateur `tools/generate_original_towers_cooling_spire.py` crée une vraie installation industrielle en trois dimensions, entièrement triangulée, différente des structures Harbor : gigantesque corps **à douze côtés et huit sections de courbure**, cuves latérales à pression, douze ailettes verticales et leurs drains, armatures forgées, bagues annulaires volumétriques, coffrets et rivets, cheminée **à seize côtés réellement profilée**, ouverture d'aération, anneau de turbine, renforts diagonaux, huit pales et signalétiques.

| Provenance mesurée | Valeur |
|---|---|
| ID Model Roblox propriétaire / modération | `95543769387033` / Approved |
| Triangles source | **6 380** |
| Groupes originaux sculptés | **148** |
| Vertices source | **3 464** |
| Matériaux source glTF 2.0 | **7**, UV/normal/tangents par MeshPart |
| Dimensions de l'original à l'échelle d'import | **6.6444 × 29.11975 × 4.956 studs** |
| Rapport source/modelage | **0.42**, décalage source vertical **31** |
| Source authentifiée | SHA256 `460a96042dc55962de0347a2e4e50ebf9d1e386c80e700b5eb40b10fee5d01cc` |
| Justificatif import et modération | [#41904066937](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41904066937) |

### Deuxième géométrie premium réelle

La source complémentaire `tools/generate_original_towers_cooling_stack.py` apporte une vraie **coque hyperboloïde évidée à double paroi**, galerie d'extraction ouverte, 330 groupes sculptés, conduites, anneaux industriels et échelle de service. Son Model `97498534364335` est Approved : **9 980 triangles, sept matériaux** et dimensions source **6.256 × 21.1646 × 5.52 studs** (échelle auteur 0.46). La source reste totalement non physique. [Architecture détaillée des deux profils](ORIGINAL_TOWERS_COOLING_VARIANTS_2026-11-04.md).

Les deux modèles réutilisent les **cinq positions et hauteurs préexistantes** en alternant **la tour creuse sur 1, 3, 5** et **la turbine sur 2, 4**. Chaque sculpture est redimensionnée uniformément selon sa propre référence de hauteur (`40 × 0.42` ou `44 × 0.46`) et sa vraie boîte `GetBoundingBox()` pour placer correctement sa base. Contrairement à une substitution `Part`, elle est réellement tridimensionnelle et ses renforts dépassent du contour, tout en demeurant strictement hors des parcours.

## Sécurité / réversibilité / performances

- **Serveur** : `PremiumTowerCoolingSpireAssets.lua` et `PremiumTowersHollowStackAssets.lua` chargent uniquement leurs deux vrais IDs approuvés, après gameplay essentiel, passe obligatoirement par `OriginalMeshScenery.sanitize`, exige exactement sept `MeshPart` non physiques, vérifie le **profil de dimensions** du modèle d'origine (rotation X/Z tolérée), puis expose `ApprovedTowerCoolingSpireTemplates.RealCoolingSpire` avec provenance/compteur.
- **Natif** : `arena-midground-mass.client.lua` indexe exactement les anciens fragments de chaque tour par `OriginalTowerCoolingSpireIndex=1..5`. Aucun morceau du sol, chemin, podium, joueur ou avertissement n'est indexé.
- **Client** : `TowerCoolingSpireMeshKit.lua` sélectionne par index l'une des deux sources approuvées et exige `VariantId=Towers`, `GeneratedMap.Arena.Base`, le vrai dossier `ArenaMidgroundMassLocal`, les cinq noms/dimensions originaux et la source approuvée. Aucun chargement externe par ID sur le client. Uniquement après montage **complet de sept MeshParts non physiques** les éléments natifs de la tour correspondante sont masqués par la transparence *locale*. Ils restent en place comme fallback, puis redeviennent visibles après retrait, changement de qualité, disparition de source, streaming ou réduction de l'arène.
- **Budget** : aucune nouvelle boucle/timer/`RunService`, aucune lumière, aucune collision, aucun `RemoteEvent`. La synchronisation utilise **le même sampler de qualité caméra** dans `scenery-lod.client.lua`. Dossier local `OriginalTowerCoolingSpireLocal` inscrit au compteur global de `VisualBudgetRules.LocalFolders`, dont le budget 440/680/900 reste effectif.

| Tier Android | Pression 0 | Pression 1 | Pression 2 | Distance max |
|---|---:|---:|---:|---:|
| Low | **0** (tours natives) | 0 | 0 | — |
| Medium | **2 tours** / 14 MeshParts | 1 / 7 | 0 | 285 + 32 studs d'hystérésis |
| High | **5 tours** / 35 MeshParts | 3 / 21 | 0 | 405 + 45 studs d'hystérésis |

`LocalOriginalTowerCoolingSpireCount` donne seulement le nombre de *vrais* Models montés (0..5). **Ce nombre n'est pas une mesure de qualité visuelle ni de FPS.**

## Conditions avant diffusion publique

1. Build Rojo complet, contrôle strict des **62 Models propriétaires approuvés** et de la source Tower Run, puis **7 suites moteur Roblox Cloud sur le dernier SHA** (pas seulement une compilation).
2. Photographies Android Low / Medium / High sur plusieurs points d'observation : vrais renforts/anneaux/cuves visibles, pas de vieux blocs ressortant à travers les détails, base et sommet correctement alignés.
3. Tester réduction de l'arène, rejointe, streaming, changement de carte, pression VFX 0/1/2 : les tours natives doivent immédiatement remplacer les 3D quand leur contrat n'est plus vérifié.
4. 30 minutes Android : mémoire, FPS/p95, surface de rendu et absence de « pop » gênant pendant le déplacement. Aucun résultat imaginé.
5. Public Roblox Place : mise à jour séparée, seulement après les contrôles de publication propres au dépôt et approbation d'une version exécutable.

**Statut :** source 3D réellement créée et approuvée, code/runtime intégré ; **validation du nouveau SHA, captures Android et publication publique restent distinctes**.
