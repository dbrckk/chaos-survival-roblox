# P4 — Supports de l'observatoire Classic : sculpture 3D originale

**10 novembre 2026.** La mégastructure nord `ArenaSignatureMegastructure` de l'arène Classic possède déjà deux paraboles concaves originales et un mât sculpté, approuvés en Roblox Model `112493873850364`. Les **cinq dernières grosses formes primitives de ce groupe** restent les deux `RelayButtressWest/East` (Part 3,5 × 33 × 4,5), deux `RelaySparWest/East` (Part 1,1 × 31 × 1,4, tournées de ±21°) et le `ServicePanel` (Part 5 × 3,2 × 0,55). Les sept éléments déjà remplacés par le kit précédent sont indépendants et ne seront pas retouchés.

Le nouveau générateur `tools/generate_original_signature_classic_supports.py` construit un ensemble réellement tridimensionnel dans l'emprise de ces cinq natives : deux contreforts porteurs à douze facettes et plusieurs sections de métal usinées, deux renforts inclinés à dix facettes et véritables conduites d'effort, panneaux d'aération avec ailettes de relief, colliers, plaques d'accès, télémétrie intégrée et boîtier technique fin. Sept groupes industriels PBR originaux, réutilisant le pipeline validé OBJ et glTF.

Les coordonnées sont celles de `MapBuilder`, converties uniformément à l'échelle 1/2 pour l'upload. Le modèle reviendra dans la carte à sa taille physique via `Model:ScaleTo`, sans distorsion d'axe. La silhouette 3D remplace cinq formes décoratives sans retirer les signaux ni les véritables pièces jouables.

Le workflow `.github/workflows/one-time-original-classic-forged-supports-20261110.yml` effectue les contrôles source (vrais triangles, matériaux, taille, empreinte, UV, normales, tangentes et 7 MeshParts potentiels) **avant** l'import Model sous le compte Roblox du créateur. L'intégration client/serveur requiert obligatoirement une approbation Roblox vérifiée et un vrai ID ; aucun identifiant inventé.

**Limite de cette première PR :** l'asset original est préparé, mais aucune nouvelle version publique du jeu n'est publiée ni testée en Engine/Android.
