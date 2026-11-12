# P4 — Sous-faces authentiques 3D des plateformes portuaires sur Android Low

**12 novembre 2026.** Statut : code source GitHub uniquement, non publié dans Roblox.

## Défaut vérifié

Les routes Harbor possèdent de vraies plateformes physiques `Arena.Platforms.PlatformN`
de 9,5 à 12,2 studs, avec dessus collidable pour la survie et le saut.
Le module `HarborDockCaissonMeshKit.lua` sait habiller leurs **flancs et
dessous** avec un caisson industriel original à géométrie forgée, trusses,
renforts, attaches et détails de manutention. Toutefois `BUDGET.Low.models=0`
interdisait toute amélioration aux appareils Android en qualité Low.

La source d'origine est le modèle Roblox approuvé **`101457508594609`**
(`ApprovedHarborDockCaissonTemplates.DockCaisson`), généré par
`tools/generate_original_harbor_dock_caisson.py` : sept familles de matériaux,
profil d'environ 14 × 3,3 × 14 studs. Le serveur valide les dimensions,
le contenu MeshPart et élimine les scripts avant distribution.

## Correctif appliqué

- **Low = 1 modèle**, sélectionné par la caméra dans le même sampler
  `scenery-lod.client.lua`, à **108 studs maximum** d'une vraie plateforme
  Harbor admissible, rétention de **14 studs** pour un modèle déjà monté.
- Sur Low le client n'accepte cette source que si le modèle importé
  possède **exactement 7 MeshParts**. Toute géométrie absente, import
  différent ou source non approuvée conserve la plateforme native.
- `OptionalVfxPressure > 0` : le caisson est immédiatement détruit
  par le propriétaire de LOD existant, **sans jamais supprimer le
  plancher, sa collision ni ses avertissements**.
- L'authentification `OwnerVerified`, `CosmeticOnly`, ID d'asset exact,
  `OriginalHarborDockCaisson3D`, absence de scripts, borne réelle,
  plateforme `PlatformN`, routes Harbor et phase de catastrophe
  restent inchangées.
- Les pièces du modèle sont toujours soudées localement au **vrai
  collider serveur** par `WeldConstraint`, `CanCollide=false`,
  `CanTouch=false`, `CanQuery=false` et `CastShadow=false`.
- **La surface supérieure de tous les MeshParts reste au minimum
  0,14 stud plus bas que le dessus jouable**. Le caisson n'est pas
  un second sol. Son repli de visibilité est déjà commandé par
  le changement de taille du plateau, `CollapsePhase`,
  `BridgeShutterPhase` et la réplication des parties du modèle.
- Medium conserve cinq modèles à 150 studs, High douze à 215 studs,
  avec leurs limites de pression historiques et les mêmes MeshParts
  déjà approuvés.
- Le dossier `OriginalHarborDockCaissonsLocal` est **déjà compté**
  dans `VisualBudgetRules.LocalFolders` : ces 7 pièces facultatives
  utilisent le budget Android partagé, sans nouvelle boucle caméra,
  nouvel asset, illumination, PBR ou réseau.

## Recette Roblox Engine / Android

1. Rejoindre Harbor en qualité Low avec `OptionalVfxPressure=0`.
   Se placer devant une vraie plateforme `HarborRoute` ou
   `HarborSpokeRoute` à moins de 108 studs. Constater **un seul
   caisson de sept MeshParts**, sans aucune surface jouable fantôme.
2. Vérifier `LocalOriginalHarborDockCaissonCount <= 1` et
   `LocalOriginalHarborDockMeshPartCount <= 7` en fonctionnement.
3. Forcer pression 1, 2, rétractation et effondrement : le caisson
   facultatif disparaît, la plateforme et ses warnings restent
   autoritaires et les bots/joueurs traversent les mêmes routes.
4. Tester une source vide, un import à plus de 7 MeshParts,
   StreamingEnabled et changement d'arène : aucune source invalide
   ne doit s'installer en Low ; réapparition possible d'un original
   valide au prochain échantillonnage LOD.
5. Comparer les captures latérales et FPS/mémoire/p95 sur
   un vrai Android Low.

Les workflows GitHub vérifient les contrats de code uniquement ;
ils ne prouvent pas la visibilité dans Roblox Engine, les FPS
mobiles ni une publication dans la Place.
