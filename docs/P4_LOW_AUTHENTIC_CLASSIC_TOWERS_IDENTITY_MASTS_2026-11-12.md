# P4 — Mâts d'identité Classic et Towers en vraie sculpture 3D sur Android Low

**12 novembre 2026 — source GitHub uniquement ; pas encore publié dans Roblox.**

## Diagnostic confirmé dans le dépôt

La génération `MapBuilder.lua` crée dans les deux arènes des repères
géants en `Part` rectangulaires, non physiques :

| Arène | Forme native | Gabarit | Modèle original approuvé |
| --- | --- | --- | --- |
| Classic | `GridMarker1..4` | 2,2 × **12** × 2,2 studs | `105555650820011` |
| Towers | `TowerSpine1..4` | 2,6 × **20** × 2,6 studs | `86423178125318` |

Les modèles ont déjà été validés avec exactement **sept MeshParts
originaux**, source `ApprovedVariantIdentitySpineTemplates`,
provenance `OwnerVerified`, `Original3DAssetId` exact,
`OriginalVariantIdentitySpine3D` et dimensions contrôlées.

Le client avait **deux désactivations indépendantes** :
`CAP.Low=0` / `RANGE.Low=0`, puis la branche `if touch then`
retournait zéro pour tout profil Low, même si le quota avait été
activé. Les mobiles conservaient les grands prismes natifs
même lorsque les sources authentiques étaient disponibles.

## Correction livrée

1. Activer **un seul modèle original** (7 MeshParts maximum)
   sur l'arène Classic **ou** Towers active, en Low
   uniquement si une vraie source est disponible.
   `CAP={Low=1,Medium=2,High=4}`.
2. Déclenchement Low à **165 studs** maximum de la caméra,
   rétention préexistante de 25 studs sur les modèles
   déjà montés. Medium 295 / High 425, quotas inchangés.
3. La branche tactile conserve le **même quota Low=1**
   plutôt que de le remettre à zéro. Les plafonds tactiles
   Medium=1 et High=2 sont inchangés.
4. Au niveau `OptionalVfxPressure==1`,
   `math.floor(1*.5)=0` supprime le modèle facultatif
   et **restaure instantanément le mât natif**. Pression 2
   conserve le même repli.
5. Une écoute `bucket.ChildRemoved` déclenche le même
   repli natif dès qu'un modèle disparaît sous l'effet
   du gestionnaire de budget visuel, **sans attendre le
   prochain échantillon caméra**.
6. Le kit masque uniquement le corps statique et vérifié.
   Les **4 couronnes `GridMarkerGlow` Classic** et les
   **12 bandes `TowerBand` Towers** restent en place :
   leurs positions, couleurs et transparences animées par
   `arena-identity-motion.client.lua` sont inchangées.
7. Tous les morceaux importés sont ancrés et
   `CanCollide=false`, `CanTouch=false`, `CanQuery=false`,
   `CastShadow=false` et `CosmeticOnly=true`.
   Aucun ajout de collider, trajet fictif, lumière, texture,
   serveur, réseau, télécommande ou RenderStepped.
8. Le dossier `ApprovedOriginalIdentitySpinesLocal` et
   sa comptabilisation `VisualBudgetRules.LocalFolders`
   sont préexistants. Le sampler `scenery-lod.client.lua`
   reste l'unique propriétaire de mise à jour caméra.

## Recette de validation Roblox Engine / Android

1. Sur Android Low, pression zéro, rejoindre Classic.
   Approcher une vraie `GridMarker` à 165 studs ;
   un original de sept MeshParts doit remplacer
   **un seul** corps natif, la couronne animée reste visible.
2. Recommencer sur Towers près d'une `TowerSpine` :
   le bloc de 20 studs doit être masqué par la vraie sculpture,
   mais **les trois `TowerBand` de cette tour doivent
   rester animées et visibles**.
3. Reculer au-delà de 190 studs d'un modèle déjà monté ;
   vérifier que l'original est restauré.
4. Simuler `OptionalVfxPressure=1` puis 2,
   retrait du MeshPart/source, transition de carte et
   retrait du modèle par le visual-budget manager :
   aucune coque invisible durable et aucun effet sur
   les animations de signal.
5. Contrôler les attributs client
   `LocalIdentitySpineMeshCount <= 1` en Low et
   `LocalIdentitySpineNativePartsReplaced <= 1`
   lorsque la source est effectivement montée.
6. Mesurer FPS, mémoire, p95 et captures avant/après
   sur de vrais mobiles Android faibles avant publication.

`tools/verify_variant_identity_spines_runtime.py` et
`tools/verify_original_3d_budget_census.py` contrôlent
les quotas, l'identité de source et les protections natives.
Ce sont **des vérifications source GitHub** : pas une validation
Roblox Studio, FPS Android, ni une publication de la Place.
