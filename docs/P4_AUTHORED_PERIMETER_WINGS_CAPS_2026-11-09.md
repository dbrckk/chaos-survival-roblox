# P4 — Deux modèles d'armure périphérique 3D originale

**9 novembre 2026. Phase de fabrication d'assets — aucune publication Roblox Place.**

Dans MapBuilder, les cinq variantes ont chacune quatre stations périphériques. AngledServiceWingL/R (3,4 × 1,7 × 5,7 studs) et LeftAngledCap/RightAngledCap (2,9 × 2,2 × 2,4 studs) sont encore des WedgeParts Roblox natifs, très visibles de près. Ce sont deux paires par station, donc **80 primitives dans les sources des cinq variantes**.

tools/generate_original_perimeter_armor.py fabrique deux sources OBJ authentiquement triangulées et originales. Chaque source contient une coque continue à huit facettes avec quatre sections de toit inclinées, des moulures latérales, des conduits de refroidissement en retrait, des longerons forgés diagonaux, des lamelles, un insert céramique et de la signalisation usinée. Sept matériaux PBR d'origine sont utilisés. Aucune géométrie de tiers ni Roblox Part n'est utilisée pour construire le mesh.

| Profil | Enveloppe de conception X × Y × Z | Cible MapBuilder |
| --- | --- | --- |
| perimeter_wing | 3,36 × 1,64 × 5,62 | AngledServiceWingL/R |
| perimeter_cap | 2,84 × 2,14 × 2,34 | LeftAngledCap/RightAngledCap |

Le workflow .github/workflows/one-time-original-perimeter-armor-20261109.yml génère les deux OBJ, les convertit en glTF avec UV, normales et tangentes et impose sept primitives matériau. Après validation, il importe les deux Model packages sur Roblox de manière **séquentielle**, avec l'uploader sécurisé existant. Ce workflow ne publie ni ne modifie l'expérience publique.

**Les identifiants Roblox ne sont jamais inventés.** Après preuves des deux imports et de la modération Approved, il faut inscrire les vrais IDs dans le registre et intégrer le montage uniquement sur les quatre vrais WedgeParts non collisionnels par station. Aucun wedge ne doit être masqué avant confirmation d'un véritable MeshPart approprié. Les collisions, les rotors, les machines, les lumières de sécurité et le système de pression GPU existants doivent rester intacts.

Les tests Engine/Android et la qualification visuelle seront exécutés uniquement au jalon de publication, conformément aux instructions du projet.
