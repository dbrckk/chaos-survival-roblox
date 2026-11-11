# P4 — Première colonne porteuse 3D authentique près du joueur sur Android Low

**Date :** 11 novembre 2026. **Statut :** correctif source GitHub ; pas de publication Roblox.

## Pourquoi ce chantier est visible

Le générateur `MapBuilder` crée sous les vrais `PlatformN` des
`PlatformSupportN_K` : piliers rectangulaires non collidables, de
hauteur variable, avec jusqu'à quatre piliers par terrasse.
`PremiumLargeStructureMeshKit` possédait déjà une famille de
colonnes sculptées créateur pour **Classic, Towers, Crossroads,
Orbital, Harbor**. Ces sources étaient utilisées seulement sur
Medium/High ; les piliers Low restaient des blocs.

## Implémentation

- Low peut monter **au maximum un seul Model** vérifié de **7 MeshParts**
  à la place d'**un seul pilier natif réel**, à **125 studs maximum**
  de la caméra, uniquement si la caméra est dans l'arène et que
  `OptionalVfxPressure == 0`.
- Le `PlatformSupportN_K` d'origine doit être présent dans le vrai
  `Arena.Decor`, ancré, non collidable/non touchable/non requêtable
  et mesurer entre **5 et 16 studs** de haut. La plateforme
  `PlatformN` correspondante doit être ancrée, collidable,
  visible, stable et non en effondrement.
- Avant de consommer la sélection unique, les **bornes exactes**
  du Model sont contrôlées : provenance `OwnerVerified`,
  `Original3DAssetId`, `CosmeticOnly`,
  `OriginalLargeStructure3D`, uniquement vrais `MeshPart`,
  aucun `LuaSourceContainer`, **exactement 7 pièces**,
  hauteur/largeur du support compatibles avec le montage en
  un seul segment, largeur sculptée au plus **3,2 studs**.
- `supportBudget` Low vaut **1 module** au maximum. L'ancien
  `supportBudget` Medium **8** et High **16** et les sélections
  Medium/High restent identiques.
- Le système existant soude les véritables MeshParts au support
  d'origine ; les variations physiques de taille ajustent les
  soudures. Le masque local
  `PlatformNativeTrimReplacementKit` cache ce seul pilier
  **uniquement après le montage vérifié**, puis le restaure
  si l'asset disparaît ou si l'état physique l'exige.
- Le Low conserve `LongCradle = 0` : on n'ajoute aucune grande
  sous-structure 3D ni aucun trajet jouable.
- Le coût visuel supplémentaire est **7 MeshParts pour 1 pilier
  primitif masqué**, soit **6 géométries visibles nettes**
  supplémentaires au maximum. Les 7 MeshParts locaux comptent
  dans l'unique dossier `ArenaPlatformIdentityLocal` déjà suivi
  par le budget Android global.
- Pas de nouveau `RenderStepped`, lumière, collision,
  texture PBR, RemoteEvent, source AssetService ni nouvel ID.
  Le retour Low au masque natif utilise le rebuild débouncé
  déjà existant sur changement de pression.

## Contrôles de réception

1. Sous une plateforme sûre et équipée d'un vrai support de 5–16
   studs, forcer Low avec pression 0 : vérifier
   `LocalOriginalNearSupportColumnCount <= 1`,
   `LocalOriginalLargeStructure3DCount <= 7` pour ce kit
   et le montage effectif de **7 véritables MeshParts**.
2. Forcer `OptionalVfxPressure=1` : vérifier la disparition des
   colonnes originales Low, la restauration du pilier rectangulaire
   et l'absence de modification des vrais colliders.
3. Déclencher disparition du Model source, streaming, CollapsePhase
   et Shrinking Arena : vérifier que les sources natives sont
   restaurées sur la bonne plateforme.
4. Sur Medium/High, vérifier le maintien des quotas et de la
   sélection des grands longerons LongCradle.
5. Mesurer l'impact FPS, p95 et mémoire **sur appareil Android
   réel** avant validation visuelle et publication publique.

Un contrôle GitHub Actions réussi ne prouve pas le rendu en Roblox
Engine ou la mise à jour de la Place publiée.
