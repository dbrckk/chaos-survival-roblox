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
