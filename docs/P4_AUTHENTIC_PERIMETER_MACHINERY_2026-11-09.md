# P4 — Boîtiers et compresseurs 3D authentiques des stations périphériques

**9 novembre 2026 — code source uniquement, pas de publication Roblox.**

## Faits constatés dans le dépôt

Les quatre vraies stations \`PerimeterStationNorth/East/South/West\` de chacune des cinq arènes comportent encore un gros \`CoreHousing\` (3,2 × 3,7 × 2,8 studs) et deux \`CompressorPodL/R\` (3,7 × 3,1 × 4,6 studs) en \`Part\` natif. Les piliers sont déjà traités séparément par \`ApprovedPerimeterButtressMeshKit\`. Les rotors d'admission, rails lumineux, lentille centrale et panneaux de guidage ne sont pas ces blocs ; ils doivent rester identifiables et visibles.

Le dépôt possède déjà **deux modèles originaux approuvés, réels et chargés côté serveur** via \`PremiumServiceEquipmentAssets\` (workflow d'import d'origine #41729439190) :
- \`ApprovedServiceEquipmentTemplates.Orbital\`, Model asset **127295681925871**, appareil de confinement sculpté, pour le boîtier central ;
- \`ApprovedServiceEquipmentTemplates.Towers\`, Model asset **106083832432833**, caisson industriel ventilé avec porte et reliefs, pour les deux compresseurs.

Ce sont des identifiants de **packages Model approuvés**, pas des MeshIds présumés. Aucun nouvel asset distant n'est demandé par le client. Les deux modèles restent indépendants de la carte courante : ils sont réemployés comme machines industrielles communes, pas comme nouvelles mécaniques de jeu.

## Modification

\`src/client/ApprovedPerimeterMachineryMeshKit.lua\` valide les deux sources côté client (dossier et modèle \`OwnerVerified\`, attributs d'origine, IDs, uniquement MeshPart, 1–12 pièces chacun, bornes et absence de scripts), et les **trois blocs natifs exacts** des stations du monde en cours (parent, nom, index, tailles, ancrage, absence de collision/touch/query et vraie base encore présente).

Les trois vrais meshes sont ajustés **uniformément dans chaque enveloppe d'origine** ; un mesh au mauvais gabarit empêche toute substitution. Aucun élément natif n'est masqué avant la réussite de l'ensemble des trois clones. Seuls ces trois gros cuboïdes sont alors masqués localement ; les avertissements, le sol, les déclencheurs, les bordures, les lentilles, le détail de turbine et les chemins des bots restent sous leur propriétaire initial.

Les clones sont ancrés, sans masse, sans collision, sans touch, sans query et sans ombre. Ils sont tous enfants du nouveau dossier \`ApprovedPerimeterMachineryLocal\`, **déclaré dans \`VisualBudgetRules.LocalFolders\`**, et comptent donc dans le budget mobile existant (440/680/900 parties locales). Réemploi exclusif du propriétaire \`scenery-lod.client.lua\` : aucune boucle supplémentaire, aucun appel réseau ajouté.

| Profil | Stations pouvant remplacer leurs trois blocs | Blocs natifs masqués au maximum |
| --- | ---: | ---: |
| Low | 0 | 0 |
| Medium | 1 | 3 |
| High Android | 2 | 6 |
| High PC | 3 | 9 |

La pression optionnelle 1 divise ce nombre de stations par deux, arrondi inférieur ; pression 2 revient au visuel natif pour les quatre stations. La caméra privilégie les vraies stations proches (170 studs Medium, 245 High, hystérésis 16). En l'absence de source, de morceau, d'une des trois pièces natives, après retrait d'une pièce mesh, lors d'une rotation de carte ou d'une diminution de la base, le kit restaure localement les trois primitives. Cette restauration ne change **aucune** physique ni aucun état serveur.

Compteurs \`LocalApprovedPerimeterMachineryStationCount\` et \`LocalPerimeterPrimitiveMachineryReplaced\` : respectivement **nombre réel de stations avec leurs trois clones**, puis nombre réel de pièces natives substituées. Ils ne prouvent ni FPS ni qualité graphique mesurée.

## Statut et réception future

Code seulement : aucun Build Validation, test Luau / Roblox Engine ou test Android n'a été effectué pendant cette itération, selon la consigne du projet. La dernière publication publique attestée demeure P2 \`ae4ae044e991ef4ca28a991991f2e11b9df49c84\` (action #42650986552). P3 et P4 ne sont pas publiés.

Au prochain jalon exact-SHA, vérifier le rendu des corps importés dans chacune des cinq arènes, l'absence d'intersection visuelle bloquante avec les turbines et la lentille, le chargement tardif des deux sources, l'effet des trois profils et de la pression, la restitution des trois blocs en cas de streaming partiel et le coût réel en MeshParts et en FPS Android. Si une source ne tient pas dans son gabarit ou ne passe pas l'authentification, les primitives restent visibles : ce n'est **pas** une substitution réellement effectuée.
