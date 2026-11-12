# P4 — Fondations extérieures entièrement sculptées et comptabilisées sur Android Low

**12 novembre 2026 — modifications GitHub ; aucune publication Roblox ni FPS moteur revendiqué.**

## Audit concret

Les modèles originaux extérieurs de l'arène possèdent une fondation
ajoutée par `OriginalMeshScenery.addFoundation`. Pour chaque grand
modèle autorisé, le serveur produit **11 pièces primitives cosmétiques**
et non collidables :
- 4 blocs `FoundationShoulder`, `FoundationInset`,
  `FoundationBallast` et `FoundationGroundPad` ;
- 2 grandes poutres métalliques avant/arrière ;
- 2 contreforts `WedgePart` ;
- 2 rails de service ;
- 1 échangeur thermique radial ou collecteur industriel.

Le client possède déjà un **véritable châssis 3D triangulé** original
`OriginalUnderdeckChassis`, asset `84582262145054`, modération
**Approved**, environ **3 072 triangles / sept MeshParts**. Le kit
`ApprovedFoundationChassisMeshKit` remplaçait les onze natives sur
Medium/High mais le profil Low était fixé à
`Low={count=0,distance=0}`.

Autre défaut : les clones de châssis étaient placés sous les modèles
3D **serveur** de `Arena.Decor.Original3DScenery`. Ils n'étaient pas
visibles pour le recensement des `VisualBudgetRules.LocalFolders`,
qui examine seulement les dossiers locaux de `workspace`. Ajouter
simplement `Low=1` aurait ajouté sept MeshParts **sans les compter** dans
les 440 Parts du budget Android.

## Correctif appliqué

1. **Low : un châssis à 128 studs maximum de la caméra**, uniquement
   sous `OptionalVfxPressure=0` et si un propriétaire extérieur
   authentique, visible et suffisamment proche existe.
2. En Low, la source doit être exactement **sept vrais MeshParts**,
   approuvés côté serveur, avec `OwnerVerified`,
   `CosmeticOnly`, `PremiumUnderdeck3D` et
   `Original3DAssetId=84582262145054`. Aucun import côté client
   ni MeshId inventé.
3. La géométrie **doit couvrir au moins 80 % de la largeur X et
   78 % de la profondeur Z** de la fondation, après une mise à
   l'échelle uniforme. Un châssis étroit ne remplace jamais
   les quatre niveaux d'un grand piédestal presque carré :
   les primitives originales restent visibles à sa place.
4. Seuls les propriétaires dotés des **11 pièces authentiques**
   sont éligibles sur Low (`OriginalFoundationPieceCount=11`).
   Une réplication partielle ou une scène incomplète ne peut pas
   masquer tout le socle. La vérification géométrique intervient
   avant réservation du seul emplacement Low, puis à nouveau
   juste avant montage.
5. Le vrai modèle est entièrement validé et positionné, puis
   monté sous `workspace.ApprovedFoundationChassisLocal`
   **avant** la mise en transparence des onze parties natives.
   Le dossier est ajouté **une seule fois** à
   `VisualBudgetRules.LocalFolders` : les **sept vrais MeshParts**
   passent maintenant dans le recensement coopératif des budgets
   `Low=440`, `Medium=680`, `High=900`.
6. Sous pression graphique Low **1 ou 2**, le compteur autorisé
   descend à zéro et le module restaure les natives puis
   retire la sculpture. Le même retour se déclenche à la
   suppression d'un clone, à la disparition d'une MeshPart,
   à la perte du modèle source ou de son propriétaire, et
   à l'occultation LOD de la base originale.
7. Le châssis reste ancré, sans collisions, toucher, requête
   ni ombre. Les sols, avertissements, catastrophes, routes
   jouables, IA et imports serveur ne sont pas modifiés.
8. **Medium/High conservent leurs quotas et portées précédents**
   (1 modèle à 215 studs ; 2 à 300 studs) et la structure
   d'hébergement existante pour leurs clones historiques.
   L'évolution du dossier local ne concerne que Low.
9. Le module réutilise **le même** échantillonnage caméra/qualité
   du `scenery-lod.client.lua`. Aucune boucle
   `RenderStepped`, `Heartbeat`, réseau ou service de rendu
   supplémentaire.

## Recette de réception Roblox Engine / Android

- Sur chaque variante, approcher un grand modèle extérieur
  ayant une fondation `OriginalFoundationBuilt` complète.
  En Low pression 0, si la géométrie convient et la caméra
  est à **≤128 studs**, vérifier **1 modèle de 7 MeshParts
  et jusqu'à 11 primitives masquées**, sans déplacement
  de la structure supérieure.
- Vérifier `LocalApprovedFoundationChassis3DCount <= 1`
  et un seul propriétaire
  `workspace.ApprovedFoundationChassisLocal` comptabilisé
  par le `VisualBudgetRules.collect`.
- Tester une fondation carrée ou une source trop étroite :
  aucune substitution trompeuse et aucun sol fantôme.
- Retirer un des 11 éléments natifs avant montage :
  le client doit conserver l'ancienne fondation complète
  et ne pas monter de source partielle.
- Décharger le propriétaire original, modifier son
  `SceneryLodHidden`, retirer le modèle local ou
  détruire une des sept MeshParts : les primitives
  natives doivent être restaurées quand elles existent.
- Passer `OptionalVfxPressure` de 0 à 1/2 :
  le modèle facultatif disparaît et les formes natales
  redeviennent visibles.
- Comparer les captures, les temps de rendu p95,
  FPS moyens, mémoire et transitions de streaming sur
  un vrai téléphone Android avant publication.

Le script `tools/verify_original_3d_budget_census.py` contrôle
le budget, la provenance, les deux axes de couverture,
les onze formes natives, le montage atomique et le repli.
Les workflows GitHub restent **des vérifications de code source**,
et non un test d'exécution Roblox Engine.
