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
