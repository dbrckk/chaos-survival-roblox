# P4 — Deux familles d'identité : Classic Grid / Towers Spines

10 novembre 2026. Audit direct de `MapBuilder.addVariantIdentity`
et du client `arena-identity-motion.client.lua`.

**Cibles propres à remplacer :** les quatre fûts `GridMarker1..4`
(Classic, 2.2 × 12 × 2.2 studs) et les quatre fûts `TowerSpine1..4`
(Towers, 2.6 × 20 × 2.6 studs). Ils restent des `Part` native
sans collision et produisent huit silhouettes très rectangulaires.

**Conserver ABSOLUMENT les éléments animés :** quatre
`GridMarkerGlow` Classic et douze `TowerBand` Towers.
Le client `arena-identity-motion` anime leur transparence,
leur couleur et les gestes du modèle. Les masquer casserait ces signaux
et créerait des conflits de visibilité entre systèmes.

Deux véritables sculptures 3D originales, chacune avec sept matériaux,
des fûts dodécagonaux profilés, nervures de résistance diagonales et
télémétrie incrustée. Empreintes spécifiées :

- Classic : **2.16 × 11.92 × 2.16** studs.
- Towers : **2.52 × 19.92 × 2.52** studs.

Leur apparence finale se combine aux signaux natifs animés ; ils ne
doivent pas ajouter de collision, de lumière indépendante ni de loop.
Les sources OBJ/glTF doivent passer les tests géométriques puis l'import
propriétaire Roblox ; aucun ID ne doit être supposé avant Approved.

Ensuite, un seul chargeur serveur et un seul kit client réutiliseront
ces deux Models avec authentification, contrôle de position et
fallback de la Partie native : Low=0, Medium mobile=1/PC=2,
High mobile=2/PC=4.

**Couverture source potentielle de ce lot : huit nouveaux fûts** dans
deux variantes distinctes, pas huit fûts simultanément en jeu ni le
pourcentage global des primitives. Les 16 bandes lumineuses ne sont
pas « remplacées » car conservées intentionnellement. Révision
Studio/Android et publication Place séparées du contrôle source.

## Import approuvé et branchement dans le jeu

Le workflow [#42874906992](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42874906992) a produit deux **Models Roblox propriétaire avec modération Approved** :

- Classic `105555650820011` — **2 364 triangles**, 73 groupes de sculpture, 7 matériaux ; centre d'identité `GridMarker`.
- Towers `86423178125318` — **3 348 triangles**, 105 groupes de sculpture, 7 matériaux ; centre d'identité `TowerSpine`.

Le chargeur serveur `PremiumVariantIdentitySpineAssets` utilise les IDs réels approuvés, appelle `OriginalMeshScenery.sanitize` et exige sept MeshParts d'authenticité par source. Le kit client `ApprovedVariantIdentitySpineMeshKit` valide les quatre positions natives de chaque variante avec les dimensions **originales** de l'arène ; les tailles physiques de la plateforme peuvent changer pendant les catastrophes sans invalider artificiellement l'art décoratif.

Chaque corps native n'est masqué qu'après montage sécurisé de 7 MeshParts. Les **4 couronnes Classic et 12 bandes Towers sont exclues du remplacement** parce que `arena-identity-motion` les anime en temps réel. La restauration du fût natif est automatique en cas de source absente, streaming, mutation ou baisse de LOD.

Capacités maximum : Low 0, Medium Android 1/PC 2, High Android 2/PC 4 ; si pression graphique 2, aucun modèle complémentaire. Les attributs client mesurent les corps **réellement montés**, sans inventer de couverture totale.

L'import d'assets et le merge GitHub ne prouvent pas le rendu dans Roblox Studio, les FPS Android ou la mise à jour de la Place publique.
