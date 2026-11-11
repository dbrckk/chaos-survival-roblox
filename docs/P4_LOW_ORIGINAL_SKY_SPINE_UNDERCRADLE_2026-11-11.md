# P4 — Le premier vrai châssis 3D des grandes passerelles sur Android Low

**11 novembre 2026.** Changement du code source GitHub ; pas de publication de la Place Roblox.

## Défaut visible confirmé dans les sources

Les vrais parcours `PromenadePlatforms` (16 dalles) et `SkySpinePlatforms`
(10 dalles) sont générés par `ArenaVariants` et `MapBuilder`. Chaque dalle
conserve ses collisions et ses avertissements de catastrophes, mais de
grandes structures primitives `PlatformUnderFrameN`,
`PromenadeN_UnderdeckTruss` et `SkySpineN_...` restent sous le pont.
`PremiumLargeStructureMeshKit.longCradle` possède déjà le Model original
authentifié **128914328933863**, châssis ajouré d'environ 22 studs,
mais le profil Low interdisait la moindre installation.

## Changement

- Le modèle `LongCradle` original est désormais éligible sur Low
  **uniquement s'il contient exactement sept véritables MeshParts**.
  Les contrôles existants restent obligatoires : dossier/Model
  `OwnerVerified`, ID exact, `OriginalLargeStructure3D`,
  `CosmeticOnly`, aucun script et dimensions bornées.
- Une seule dalle physique `PlatformN` issue d'une vraie
  promenade ou de la Sky Spine peut recevoir la sculpture : vraie
  plateforme ancrée, collidable, visible, stable, non effondrée,
  caméra dans la zone de l'arène et à **125 studs maximum**.
- La sélection Low contrôle **avant réservation** la longueur,
  largeur, hauteur et l'échelle réelles de la source. Les garde-fous
  `longCradle` existants s'appliquent une seconde fois au montage ;
  aucune silhouette 3D trop petite ne peut remplacer un châssis de
  30 studs sans couvrir suffisamment sa longueur.
- **Quota partagé** : Low possède **un seul modèle 3D de grande
  structure** au total, soit un `LongCradle` **OU** la
  `PlatformSupportN_K` sculptée introduite précédemment.
  La passerelle compatible est prioritaire ; sans source 3D de
  passerelle éligible, le pilier sculpté peut être sélectionné.
  Les plafonds Medium/High (2/4 longcradles, 8/16 modules support)
  sont conservés.
- Sous `OptionalVfxPressure >= 1`, le client Low utilise ses
  structures natives. Le propriétaire visuel reconstruit via
  l'observateur de pression existant, sans nouveau tick.
- La sculpture suit les `Weld` et les snapshots `RouteTier`
  existants. Le `PlatformNativeTrimReplacementKit` masque les
  sous-structures rectangulaires **uniquement après montage vérifié**
  puis les restaure si la source/plateforme disparaît ou si
  l'effondrement rend le masquage dangereux.
- Le coût Low maximum dans ce propriétaire est **sept MeshParts
  originaux** pour les grandes structures, recensés dans
  `VisualBudgetRules.LocalFolders.ArenaPlatformIdentityLocal`.
  Aucun ID, texture, physique, lumière, script distant, réseau ou
  boucle de rendu ajouté.

## Réception avant toute publication

1. Sur Sky Spine / Promenade en Low sans pression, caméra proche
   d'une dalle compatible, vérifier un vrai châssis de sept MeshParts
   et `LocalOriginalNearBridgeCradleCount <= 1`.
2. Vérifier que `LocalOriginalNearSupportColumnCount = 0` si un
   `LongCradle` Low est monté. L'absence de source LongCradle
   rend possible le support sculpté précédent.
3. Sous Low `OptionalVfxPressure = 1`/2, retrouver les
   `PlatformUnderFrame`, `Promenade*_UnderdeckTruss` et
   `SkySpine*_Undercarriage` natifs sans modèle supplémentaire.
4. Exécuter les spécifications Roblox Engine sur le commit exact
   puis contrôler collision, avertissement d'effondrement,
   Shrinking Arena et source streamée tardivement.
5. Mesurer FPS/p95/mémoire sur un smartphone Android Low : une
   validation CI du dépôt n'est **pas** une preuve de ces métriques.

**Limites :** fonctionnalité conditionnelle à la présence du Model
approved répliqué et aux dimensions réelles. Pas de test moteur
Roblox ni de téléversement public effectué par ce changement.
