# P4 — Vrais anneaux 3D sur Low et couronne Towers sculptée

11 novembre 2026 — code source de Chaos Survival. **Ce document n'est ni
une confirmation de rendu Roblox Studio ni une preuve de publication
de la Place publique.**

## Inventaire avant modification

- **Orbital nord** : `ArenaSignatureMegastructure.ReactorArc1..16`,
  seize `Part` rectangulaires non physiques arrangés en anneau
  vertical de rayon 20 studs. Son modèle véritable et approuvé
  `125070862497818`, à sept `MeshPart` originaux, ne s'affichait
  que sur Medium/High.
- **Orbital sud** : `SouthHorizonMonument.ObservationArc1..14`,
  quatorze `Part` similaires ; tore original modéré Approved
  `124474310430876`, sept `MeshPart`, jusqu'ici Medium/High.
- **Towers** : `Arena.Atmosphere.TowerCrown` est une seule
  `Part` Neon carrée **20 × 0,35 × 20 studs**, à 22 studs au-dessus
  du centre. Elle n'a pas de collision et se superpose à la
  skyline sans servir de route ni de signal de catastrophe.

## Lot livré en code

1. Les deux kits Orbital permettent désormais **une** sculpture
   approuvée chacun sur **Low**, si leurs véritables modèles sont chargés
   et si la caméra se trouve à 340 studs au plus (+ la rétention existante).
   Au premier niveau de pression graphique, les deux kits Low
   restituent l'intégralité des 30 Parts natives ; au deuxième
   niveau, même restauration sur Medium/High. Les vérifications strictes
   d'appartenance à la vraie carte et de géométrie sont inchangées.
2. Le nouveau `ApprovedAtmosphereCrownMeshKit.lua` transforme
   conditionnellement la couronne Towers en **vrai tore horizontal
   à 72 sections**, réutilisant **le même modèle Roblox approuvé
   `125070862497818`**. C'est une copie locale supplémentaire
   d'un asset déjà importé par le serveur ; aucune deuxième requête
   AssetService ni nouvel asset Roblox n'est créé. Sa couleur d'éclairage
   (`SIGNAL`) suit celle du vrai `TowerCrown`.
3. Le kit Towers vérifie : `GeneratedMap/Arena` original,
   `VariantId=Towers`, `VisualVersion=2`, `Base` physique
   320 studs, `TowerCrown` non physique à la bonne position,
   taille/rotation/couleur Neon et source propriétaire avec
   **exactement sept MeshParts** et un sous-mesh SIGNAL.
   Le modèle est entièrement monté avant de masquer la Part.
   Si l'import, les matériaux de signal, la caméra, la rotation,
   l'appartenance, le modèle ou le budget deviennent invalides,
   la primitive d'origine revient automatiquement.
4. Le tore Towers intègre `PremiumNearfieldPbrKit` via le quota
   partagé déjà appliqué à ses autres sculptures sur Medium/High.
   Les cartes 2K normales, rugosités, métaux et couleurs sont
   les **seize textures existantes**, jamais de nouvelles sources.
5. `ApprovedAtmosphereCrownLocal` est recensé dans
   `VisualBudgetRules.LocalFolders`. Les mêmes passages LOD
   (0,65 / 0,90 s) contrôlent tout, sans nouvelle boucle RenderStepped,
   physique, remotes, HUD ni collision.

## Budget et métrique honnête

| Arène et famille | Low (sans pression) | Parts natives éligibles | MeshParts nouveaux au maximum |
| --- | ---: | ---: | ---: |
| Orbital nord, tore réacteur | 1 modèle | 16 | 7 |
| Orbital sud, tore observation | 1 modèle | 14 | 7 |
| Towers, couronne supérieure | 1 modèle | 1 | 7 |

Les deux lignes Orbital sont dans la **même carte**, alors que la
couronne Towers concerne **une autre carte**. La somme 31 désigne
le nombre de **définitions de primitives supplémentaires éligibles
sur plusieurs variantes**, et ne signifie jamais 31 nouvelles
formes réellement remplacées à l'écran. Sur une arène Orbital Low,
le gain potentiel est **30 Parts primitives pour 14 MeshParts**,
sous réserve de présence de sources, de LOD et de visibilité.

Le tore nord étant déjà importé pour Orbital par
`PremiumOrbitalSignatureRingAssets`, réutiliser le même
template pour Towers n'ajoute ni requête ni parallélisme.
**Correctif du 11 novembre 2026 :** le même chargeur accepte désormais
`Orbital` **ou** `Towers` comme arène prioritaire à **22 secondes**
(auparavant Towers attendait le délai de secours de **42 secondes**).
Le plafond de deux requêtes globales reste inchangé. Sous charge ou
réseau lent, le modèle approuvé peut toujours arriver plus tard.
Sur les trois autres variantes, le délai de secours reste 42 secondes.

Le halo de balisage `PerimeterPulse1..12`, les huit nœuds Orbital
`OrbitalNode`, le cœur `OrbitalCore`, les bandes et balises
de tours restent volontairement natifs : ils forment le langage
de signalisation et ne doivent pas devenir un anneau solide,
épais ou gênant les dangers sous prétexte de remplacer des Parts.

## Validation à réaliser au jalon de publication

La CI source et les tests statiques disponibles doivent être vérifiés
sur le SHA exact. Il faudra encore inspecter visuellement les tores
dans Roblox Engine, mesurer les FPS/p95 sur Android Low et confirmer
leur retour natif lors d'une baisse de performance ou d'un
StreamingEnabled tardif. **La géométrie 3D modérée Approved n'est
pas une validation visuelle AAA.**
