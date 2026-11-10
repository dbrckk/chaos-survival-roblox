# P4 — Échangeur à deux étages sculpté pour Crossroads

**Actualisation intégrée — 10 novembre 2026.** L'action GitHub #42778699782 a validé l'OBJ/glTF original avec **4 356 triangles**, sept groupes de matériaux et limites source **47,68 × 11,73404 × 6,76 studs**. Roblox a réellement créé le Model `96622579843060` (**Moderation: Approved**). Le chargeur serveur et le kit client sont maintenant branchés en source pour un remplacement atomique des quatre primitives. Le texte ci-dessous présente aussi l'étape de fabrication antérieure ; aucun test moteur ni publication de Place n'est revendiqué.


10 novembre 2026. La cible est **la mégastructure décorative au nord de Crossroads**, et non les passerelles, rails et sols jouables.

Dans `src/server/MapBuilder.lua`, `addArenaSignatureMegastructure` instancie `LowerExchange` (Part 42 × 2 × 6 studs, position locale 0,29,0), `UpperExchange` (Part 48 × 1,3 × 5,4 ; 0,36,5,0), et `CantileverWest/East` (WedgePart 11 × 4 × 7 ; ±18,3,38,0). Les quatre masses forment encore une architecture trop rectangulaire. Les deux jambes de 34 studs, les longerons inclinés, le Switchboard et l'antenne SignalPylon/SignalCrown sont hors du lot afin de conserver identité et lisibilité.

Le nouveau fichier `tools/generate_original_signature_crossroads_interchange.py` fabrique un vrai modèle unique avec deux ponts longitudinaux à profils chanfreinés distincts, leurs cantilevers forgés, des dizaines d'entretoises diagonales réellement ajourées, des garde-corps, joints et aérations en relief. Les sept matériaux industriels PBR du projet sont utilisés comme **sept groupes géométriques sources**, et non simulés par de simples cubes Roblox.

L'enveloppe réelle des quatre natives est 48 × 12 × 7 studs, centrée à y=34 par rapport à la mégastructure. Le Model source vise cette enveloppe, sans étirer indépendamment ses axes. Un seul Model est destiné à remplacer **les quatre pièces natives comme une opération atomique** : aucune pièce n'est masquée si le Model source ou les quatre natives ne sont pas validés.

Le workflow `.github/workflows/one-time-original-crossroads-interchange-20261110.yml` reconstruit l'OBJ, contrôle triangles/matériaux/UV/normales/tangentes et seulement ensuite procède à un import du Model Roblox créateur. Aucun identifiant n'est présumé. La validation Roblox Engine/Android, les transitions LOD et la publication publique du jeu restent séparées du travail source.
