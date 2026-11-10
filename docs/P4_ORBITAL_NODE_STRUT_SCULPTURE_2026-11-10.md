# P4 — Sculptures originales des huit nœuds et huit supports Orbital

10 novembre 2026. Les `OrbitalReactorNode1..8` sont des sphères natives
et les `OrbitalReactorStrut1..8` des poutres droites. Deux **assets
Model distincts, non physiques**, sont conçus pour remplacer ces familles
sans modifier le gameplay :

- `variant_orbital_sculpted_node` : volume sculpté, trois grands tores
  ouverts orthogonaux, surface multi-latitude, panneaux de refroidissement,
  six joints porteurs et balises ; environ 4,36 studs par axe.
- `variant_orbital_trussed_strut` : vraie structure triangulée ouverte,
  quatre longues poutres métalliques, haubans et platines usinées,
  environ 8,46 × 1,24 × 1,10 studs.

Les deux modèles utilisent les sept groupes matière existants et des
triangles OBJ convertis en sept MeshParts glTF, pas de simples Parts.
Une paire de vrais Models Roblox doit être approuvée par la modération
avant activation ; les ID ne sont pas inventés.

Les 8 nœuds alternent 9/12 studs de hauteur et les 8 supports sont placés
à Y=7 suivant l'angle d'origine. Le code runtime devra vérifier chaque
position et l'orientation exacte d'origine, monter séparément les
deux familles par LOD et restaurer les natives sur échec ou streaming.
Les compteurs refléteront la présence *réelle*, et non 16/16 toujours
chargés. La QA Studio, Android et la publication de Place restent des
étapes distinctes.

## Import Roblox modéré et activation dans le code

GitHub Actions [#42869295978](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42869295978) a importé, dans l'ordre, deux Models propriétaire **Approved** : nœud `104654294187035` (2 444 triangles) et support `138666009076890` (2 488 triangles). Les deux IDs de packages figurent au registre et sont vérifiés avant activation.

Le module serveur `PremiumOrbitalReactorLandmarkAssets` charge et assainit les Models séparément en vérifiant **sept MeshParts** par source. Le module client `ApprovedOrbitalReactorLandmarkMeshKit` sélectionne les huit paires existantes **avec leurs positions, tailles, formes et rotations exactes** puis installe les 14 MeshParts d'une paire *avant* de masquer son nœud sphérique et son support natifs.

Budget de paires simultanées : Low 0 ; Medium Android 1/PC 3 ; High Android 3/PC 6, sous contrainte de distance et de pression GPU. Les deux Parts originales de chaque paire sont restaurées en cas de perte source, changement de carte, de streaming, de géométrie ou rétrogradation LOD. Aucun collider ni nouvelle boucle RenderStepped n'est introduit.

Il existe **16 pièces natives éligibles dans la variante Orbital**, et non 16 remplacements garantis simultanément. Les attributs `LocalOrbitalReactorSculptPairCount` et `LocalOrbitalReactorNativePartsReplaced` comptabilisent les montages observés sur chaque client.

La CI source ne remplace pas une mesure de FPS Android, la validation in-engine ou la publication de la Place Roblox, qui reste un processus distinct.
