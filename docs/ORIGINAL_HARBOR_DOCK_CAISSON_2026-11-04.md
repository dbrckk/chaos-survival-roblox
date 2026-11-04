# Storm Harbor — caissons portuaires 3D originaux sur plateformes physiques

**4 novembre 2026** · source interne du projet · **Model Roblox `101457508594609`** · modération **Approved** · import/garde-fou géométrique : [GitHub Actions #41844409855](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41844409855).

## Transformation réellement construite

Les quatre voies physiques `HarborRoute=1..4`, `HarborStep=1..7` représentent 28 plateformes carrées de **9,6 à 12 studs** sur 2 studs d'épaisseur. Les quatre accès de quai `HarborSpokeRoute=1..4`, `HarborSpokeStep=1..4` ajoutent 16 plateformes de **10,5 à 12 studs**. Ce sont des **surfaces de jeu existantes** : ne pas les remplacer par une surface cosmétique non collidable ni masquer leur dessus.

Le modèle 3D créé dans `tools/generate_original_harbor_dock_caisson.py` est un **vrai ensemble manufacturé** à 7 matériaux et triangles. Il contient :
- enveloppe métallique facettée de sous-châssis ;
- quatre flancs forgés, amortisseurs, gorges hydrauliques et signalétique de maintenance ;
- 12 verrous de fret tridimensionnels et des cassettes diélectriques ;
- deux couronnes portantes sous le plancher, quatre supports longitudinaux, contreventements croisés et capot de service.
Il ne s'agit **pas d'une série de Roblox Parts**. Les sept MeshParts sont issus du véritable export OBJ triangulé et glTF 2.0 UV/normal/tangent, modéré par Roblox en tant que Model original propriétaire.

La **partie supérieure du maillage reste au moins 0,14 stud sous la surface collidable** après installation ; le dessus de chaque plateforme de jeu **reste visible et autoritaire**. Le maillage ne devient jamais une fausse plateforme, ne reçoit pas de collisions, ne masque pas les alertes, et ne modifie pas le saut ou l'IA. Les pans en relief et le dessous sculpté enveloppent les flancs auparavant cubiques. Les petits anciens chants natifs subsistent comme fallback, parfois recouverts par la sculpture ; on ne prétend pas avoir retiré les colliders eux-mêmes.

## Contrat de sécurité, de source et de flux

Le chargeur `PremiumHarborDockCaissonAssets.lua` ne charge QUE l'asset vérifié `101457508594609` via `AssetService.LoadAssetAsync`, après une attente de 88 s pour ne pas bloquer les imports critiques. Il n'expose au client que des `MeshPart` désarmés via `OriginalMeshScenery.sanitize`, 1–12 pièces, source aux dimensions contrôlées, et des attributs de provenance `Original3DAssetId`, `OriginalHarborDockCaisson3D`, `OwnerVerified`, `CosmeticOnly`.

Le kit client `HarborDockCaissonMeshKit.lua` utilise le même cycle caméra et tier existant de `scenery-lod.client.lua`. Seule la carte `Harbor` et les 44 plateformes de route/de quai **identifiées par leurs attributs serveur** sont éligibles ; les modèles sont sélectionnés par distance/direction caméra. Le dimensionnement isotrope `9,6/12..12/12` adapte le modèle au vrai tablier sans créer de nouvelle surface. Le maillage reste soudé et inerte.

La transparence, la collision, le `CollapsePhase`, le `BridgeShutterPhase`, les dimensions et l'ascendance d'une plateforme sont vérifiés en permanence par événements légers et au moment de l'échantillonnage. Tout changement rendant l'objet invalide cache/démonte l'art cosmétique. Une disparition inattendue de `MeshPart` révoque immédiatement le reste du modèle. Réduction du sol pendant `ShrinkingArena`, changements de carte, streaming, source refusée ou tier Low : **retour complet au rendu natif existant**, sans aucun risque d'invisibilité d'un obstacle.

## Budget et observabilité Android

| Qualité | Pression FPS 0 | Pression FPS 1 | Pression FPS 2 |
|---|---:|---:|---:|
| Low | 0 modèles | 0 | 0 |
| Medium | 5 modèles | 2 | 0 |
| High | 12 modèles | 6 | 2 |

Tous les MeshParts résident dans `OriginalHarborDockCaissonsLocal`, déclaré dans `VisualBudgetRules.LocalFolders`. Les attributs `LocalOriginalHarborDockCaissonCount` et `LocalOriginalHarborDockMeshPartCount` reflètent le nombre **réellement monté** de modèles et de MeshParts complets (ce n'est ni un FPS mesuré ni une preuve de pixels).

## Critères avant toute publication

1. Build et sept suites Roblox Cloud sur le **même commit final**, sans déclencher une mise à jour du jeu public.
2. Vérifier la présence réelle de l'asset, l'orientation du maillage, son enveloppe, les plans supérieurs, les 28+16 voies de quai, les cases `Low/Medium/High`, ainsi que `LocalOriginalHarborDockCaissonCount` et ses budgets.
3. Parcours humain et bot à l'aller/retour sur les quatre voies cargo et les quatre quais : sauts, absence de bord trompeur, alertes météore/lave/freeze et collisions toujours crédibles.
4. Détruire une pièce MeshPart dans Studio E2E, forcer un shrink et un aller-retour de cartes : aucun résidu de `WeldConstraint`, aucun morceau flottant et effet absent quand la vraie plateforme n'existe plus.
5. Mesurer sur Android réel FPS/p95 et mémoire des scènes denses et au cours de plusieurs manches. Le code statique ne certifie pas un rendu AAA ni un appareil physique.

**Statut de ce document : code source du lot ; pas encore publication publique ni revue visuelle réelle.**
