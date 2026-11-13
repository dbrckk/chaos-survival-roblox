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

## Risques restants et prochain travail

Le recensement source rapporte désormais exactement **2** familles encore
protégées par un garde `base.Size.X/Z < 318`, contre 5 avant ce travail :

- `PremiumGroundMeshKit.lua` : les 36 modules de revêtement non collidable
  changent à la fois de taille et de `CFrame` avec le sol. Le modèle 3D
  actuel est ancré à l'ancien `CFrame` : avant de supprimer le garde, il
  faut suivre les événements du véritable module, conserver les panneaux
  de danger/contraste et faire correspondre les dimensions X/Z.
- `PremiumRouteMeshKit.lua` : ce kit couvre à la fois des routes
  `RouteTier` qui changent de taille, des ponts de longueur variable et
  des plateformes non compactées. Il faut classifier **par plateforme**,
  pas enlever une condition globale : les protections `safePlatform`,
  `BridgeShutterPhase`, `CollapsePhase`, taille initiale, repli des
  panneaux et double châssis LongCradle restent obligatoires.

La réduction de 5 à 2 désigne des **modules gardés par cet ancien test**,
pas une couverture globale de tous les modèles ou primitives présents à
l'écran. L'inventaire général des structures et la liste des remplacements
futurs restent dans
[`audit/P4_AUDIT_EXHAUSTIF_STRUCTURES_RESTANTES_2026-11-13.md`](audit/P4_AUDIT_EXHAUSTIF_STRUCTURES_RESTANTES_2026-11-13.md).
