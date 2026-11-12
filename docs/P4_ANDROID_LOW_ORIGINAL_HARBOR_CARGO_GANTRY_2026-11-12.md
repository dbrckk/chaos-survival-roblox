# P4 — Grande arche de fret Harbor en véritable sculpture 3D sur Android Low

**12 novembre 2026.** Statut : modification du dépôt GitHub ; ni test Roblox Engine ni publication de la Place.

## Défaut visuel documenté dans les sources

`PromenadeArchitecture` produit six grandes arches identitaires,
trois par voie, sur des **plateformes jouables et collidables**.
Chaque arche Harbor assemble **neuf blocs natifs sans collision** :
les deux pylônes, deux diagonales, la traverse supérieure,
la sous-structure et les trois pièces de manutention
(bras de grue, caisse suspendue et chaîne).

Le dépôt possède déjà la sculpture authentique de fret
`ApprovedHarborPromenadePortalTemplates.CargoGantry` :
asset créateur approuvé **`134157110756659`**, environ
20 studs de hauteur et d'envergure, sept pièces géométriques
dans son modèle original. Elle remplaçait les blocs en
Medium/High, mais `BUDGET.Low.count = 0` interdisait tout
remplacement sur le profil mobile le plus important.

## Changement appliqué

- **Low autorise une seule arche authentique de sept MeshParts**
  à une distance maximale de **118 studs** de la caméra, et
  conserve le modèle déjà présent jusqu'à 132 studs pour limiter
  les changements intempestifs.
- La sélection reste dans le `scenery-lod.client.lua`
  existant, **sans nouveau RenderStepped, Heartbeat ou polling** ;
  elle cible exclusivement les vrais decks `PlatformN`,
  `PromenadeLane` 1/2, `PromenadeStep` 2/4/7,
  `ChaosPermanentRoute` et source approuvée authentique.
- Le profil Low exige **exactement sept vrais MeshParts**.
  Les contrôles de dossier et source `OwnerVerified`,
  `CosmeticOnly`, `Original3DAssetId` exact,
  `OriginalHarborPromenadePortal3D`, absence de scripts,
  volume et dimensions restent appliqués avant le montage.
- Les sept MeshParts sont non-collidables, sans toucher ni
  requête ; la vraie plateforme, les sauts, les dangers et les
  avertissements restent entièrement gérés par le serveur.
- **Une arche montée couvre neuf anciens blocs non physiques**,
  masqués avec `LocalTransparencyModifier` seulement après
  le montage complet et vérifié du modèle original.
  Ces neuf blocs reviennent dès que le remplacement n'est
  plus sûr ; les éléments tardifs de `StreamingEnabled`
  sont suivis par `Decor.ChildAdded`.
- **`OptionalVfxPressure >= 1` supprime immédiatement toute
  sélection Low**, y compris le modèle déjà résidant. Aucun
  PBR supplémentaire n'est autorisé à ce niveau de pression.
- Les limites Medium **2** et High **6** ne changent pas, de
  même que leurs règles historiques de pression et de PBR.
- Le dossier `OriginalHarborPromenadePortalsLocal` est déjà
  inscrit à `VisualBudgetRules.LocalFolders` : toutes les
  MeshParts supplémentaires sont comptabilisées par le
  même budget adaptatif Android.

## Contrôles de réception Roblox Engine

1. Rejoindre Harbor avec caméra près d'une véritable arche et
   tier Low à pression 0 : attendre la source approuvée puis
   constater **un seul vrai Model de sept MeshParts**
   et les neuf éléments géométriques natifs correspondants masqués.
2. Vérifier `LocalOriginalHarborPromenadeCount <= 1`.
   Aucun extra `SurfaceAppearance` PBR ni lumière de décor
   ne doit être introduit par ce lot.
3. Forcer `OptionalVfxPressure = 1` puis 2 : le Model est
   retiré et chaque bloc natif réapparaît ; collisions
   et dangers demeurent inchangés.
4. Supprimer une pièce du vrai Model, faire entrer des parties
   `Decor` tardivement, lancer `CollapsePhase`, réduire
   la passerelle via Shrinking Arena : pas de géométrie
   fantôme ni de blocage du trajet.
5. Mesurer FPS, mémoire et p95 sur Android Low et comparer
   des captures de la grande arche avant/après.

Les tests GitHub sont des **vérifications statiques** du code ;
une réussite CI ne prouve pas le chargement dans la Place
Roblox publique, ni les performances sur un téléphone réel.
