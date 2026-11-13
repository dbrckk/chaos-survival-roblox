# P4 — habillage 3D qui suit les vraies plateformes pendant ShrinkingArena

**Date :** 13 novembre 2026. **Projet :** Chaos Survival. **Branche :** `main`.

## Diagnostic d'origine

Le serveur `src/server/Disasters/ShrinkingArena.lua` réduit de 55 % en X/Z
la taille du sol et des véritables plateformes `RouteTier`. Les plateformes
ont leur `CFrame` mis à jour de façon autoritaire, sans modifier les
collisions ni l'état des dangers. Auparavant, cinq propriétaires de MeshParts
clients retiraient l'habillage approuvé dès que `base.Size.X/Z < 318`,
y compris quand l'habillage pouvait suivre une vraie plateforme. Leurs
géométries restaient remplacées par les visuels natifs de repli.

## Trois familles migrées vers une adaptation réelle

| Famille | Module | Visuel qui suit le deck | Origine 3D |
|---|---|---|---|
| Harbor, 28 switchbacks + 16 spurs potentiels | `src/client/HarborDockCaissonMeshKit.lua` | Caisson/armature sous la plateforme réelle, recalée sous sa face supérieure | `101457508594609` |
| Harbor, six portes cargo des promenades | `src/client/HarborPromenadePortalMeshKit.lua` | Arche industrielle : X/Z diminuent avec le pont, la hauteur verticale est préservée | `134157110756659` |
| Sky Spine, quatre portails par monde éligible | `src/client/SkySpineCrownMeshKit.lua` | Sculpture d'entrée, signal et passerelles d'ornement ; X/Z suivent le deck, hauteur préservée | `71492051540032` |

Ces nombres décrivent les candidats authentiques du jeu, **pas** des modèles
simultanément résidents. Les limites par qualité, caméra, pression et appareil
restent strictement inchangées.

### Contrat technique

1. Le sol doit être dans l'arène courante `GeneratedMap/Arena` et fournir
   des attributs initiaux numériques, finis et >=318 :
   `OriginalSizeX`/`OriginalSizeZ`. Le ratio de rétrécissement doit être
   uniforme et situé dans `[0.445, 1.005]`.
2. Le deck doit être réellement **anchored, collidable et visible**,
   propriétaire `Platforms`, en route `RouteTier` et disposer de toutes
   ses métadonnées propres à la famille. Son emprise actuelle doit être
   cohérente avec son emprise d'origine multipliée par le ratio du sol.
3. Seul le contenu local et non collidable du modèle authentique bouge.
   Les anciens `WeldConstraint` cosmétiques ont été remplacés par des
   `Weld` locaux, paramétrés via leur `C0`, qui ne déplacent **jamais**
   le deck ancré. Les MeshParts sont rescalés lors des événements
   `Size` existants, avec un pas minimal pour éviter les allocations et
   les changements de propriétés à chaque sous-millimètre.
4. En présence d'un danger `CollapsePhase`, d'un
   `BridgeShutterPhase` anormal, de pièces manquantes, de provenance
   invalide ou d'une empreinte incohérente, la source 3D est cachée et
   les primitives/signalétiques natives restent ou redeviennent visibles.
   Les collisions et la navigation Roblox restent entièrement serveur.
5. Aucun nouveau `RenderStepped`, `Heartbeat`, RemoteEvent, téléchargement
   client, modèle importé ou piste de rendu n'a été ajouté. Les plafonds
   Android Low et `OptionalVfxPressure` sont conservés ; les PBR de
   proximité et la politique d'éclairage des couronnes restent en place.

## Contrôles exécutés

- [Recensement structurel après les trois adaptations — succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43444263597).
- [Budget des propriétaires 3D, y compris la couronne — succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43444201967).
- [Budget 3D après les arches Harbor — succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43443719038).
- [Build Validation après le refit des caissons — succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43443214085).
- [Roblox Open Cloud Engine Tests, 7 suites, caissons uniquement — succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43443344678), exécutées sur `b330e97b4c8ad5a12cda16fb7b6a63b857f00f8c`.

**Portée de validation :** les contrôles source et le budget sont verts
après les trois adaptations. Le run Engine sur `b330e97b` est antérieur
aux modifications des arches et couronnes : **il n'atteste pas du HEAD final**.
Aucune capture Android, mesure FPS ni publication publique n'a été effectuée
dans ce lot.

## Actualisation : source de vérité et repli StreamingEnabled

**Mise à jour du 13 novembre 2026, seconde passe.** Les deux familles
initialement indiquées ci-dessus comme restant à migrer ont été corrigées
sur `main` lors de l'étape suivante :

- `PremiumGroundMeshKit.lua` recale les **36** revêtements sur les vraies
  dalles non collidables avec vérification de leur position, dimensions
  X/Z et provenance d'origine. Il conserve le contraste lave et les
  avertissements. Toute disparition d'un modèle 3D déclenche maintenant
  une restauration immédiate des joints/seams natifs et de leur état
  de résidence, même entre deux échantillonnages LOD.
- `PremiumRouteMeshKit.lua` distingue les decks `RouteTier` (X/Z),
  les véritables `ChaosSkybridge` (axe long) et les decks dont
  seule la position bouge. Chaque modèle 3D suit uniquement son véritable
  plateau collidable, avec repli si le deck, un avertissement, un mesh
  ou un assemblage LongCradle ne respecte plus le contrat.

Le [recensement visuel source du commit `5aa2470`](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43449489984)
confirme **0** ancien garde global `base.Size.X/Z < 318` restant dans
les 3D MeshKits, contre 19 au départ. **Ce nombre n'est pas un taux de
remplacement 3D de toute la carte.**

### Défauts de repli corrigés sur les couronnes et caissons

Sur le code précédant cette seconde passe, `SkySpineCrownMeshKit.lua`
acceptait un modèle encore présent même si un MeshPart interne avait disparu,
si sa soudure n'existait plus ou s'il avait acquis une propriété physique
incompatible. Le masque natif, le compteur de résidence et les PBR
pouvaient alors annoncer un modèle 3D incomplet. Le kit vérifie désormais
chaque MeshPart et sa soudure, observe `DescendantRemoving` et restaure
immédiatement le vrai portique natif sans attendre le sampler caméra.

Le `HarborPromenadePortalMeshKit.lua` applique le même contrat strict aux
**neuf** structures industrielles dont il masque la version primitive :
une soudure ou un MeshPart manquant ne donne plus droit au masquage ni au PBR.

Dans `HarborDockCaissonMeshKit.lua`, une correction distincte porte
sur les vrais événements `Size` : le gestionnaire `changed()`
vérifiait auparavant uniquement la validité de la plateforme, sans
recalculer la sculpture si le deck demeurait valide pendant le shrink.
Il déclenche maintenant `visibility()`, donc `refit()`, **à chaque
réduction réelle de la plateforme**. Les caissons retirés extérieurement
libèrent immédiatement leurs écouteurs, et les rapports excluent
les modèles incomplets ou dotés de collisions décoratives accidentelles.

### Vérifications et limites

- [Budget Android 3D après correctifs Harbor — réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43449490015).
- [Audit complet après correctif Harbor — réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43449489984).
- [Audit après contrôle partiel de Sky Spine — réussi](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43449113494).

La CI de code/source peut confirmer les conditions vérifiables
statiquement ; elle **ne prouve pas à elle seule** la qualité du rendu,
les événements de streaming sur un client Android ou les FPS en jeu.
Avant publication, relancer les suites Roblox Engine et effectuer
une session visuelle Android sur les cinq arènes, notamment un shrink
avec fermeture/ouverture de passerelle, alertes de catastrophe,
rotation de caméra et changement de niveau graphique.

Les modèles 3D restants, les primitives natives et les priorités
esthétiques sont inventoriés dans
[`audit/P4_AUDIT_EXHAUSTIF_STRUCTURES_RESTANTES_2026-11-13.md`](audit/P4_AUDIT_EXHAUSTIF_STRUCTURES_RESTANTES_2026-11-13.md).
