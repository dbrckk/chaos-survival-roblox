# P4 — Passer les entrées Crossroads en vraie 3D

10 novembre 2026. Le générateur de Crossroads comporte quatre
`CrossroadGate1..4` et huit `CrossroadPost{index}_{-1,1}`,
soit **12 primitives non physiques** à proximité du joueur, encore
visibles sous forme de barres et piliers.

Une sculpture propriétaire originale avec sept matériaux a été produite
pour remplacer **une arche complète**. Profil industriel à fût courbe
multisegment, ouvert au centre pour conserver l'entrée et sa lisibilité,
avec rail lumineux, boulons, nervures, renforts inclinés, panneaux gravés.
La source mesure environ **19.2 × 10.6 × 1.72 studs**. Elle est orientée
de 90 degrés sur deux entrées pour correspondre à la MapBuilder.

La source est validée par Python : OBJ triangulé, sept groupes glTF
authentiques avec UV, normales et tangentes, enveloppe, et quatre vrais
emplacements natifs. Un workflow déclenche l'import d'un unique Model
Roblox contrôlé propriétaire **après fusion et vérification**. Pas de
création d'AssetId fictif ni de modification de la Place par l'import.

L'intégration au runtime devra monter les 7 MeshParts originales avant
de masquer les 3 pièces natives de chaque portail, avec retour automatique
sur streaming/LOD/erreur, sans collision et sans bloquer les traversées.

Ne déclarer ni l'intégration gameplay ni la publication publique terminées
avant réception de la modération Approved et du contrôle runtime.
