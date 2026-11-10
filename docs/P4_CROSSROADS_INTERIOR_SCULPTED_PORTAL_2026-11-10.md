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

## Import et intégration validés dans le dépôt

L'import d'asset propriétaire [GitHub Actions #42872132972](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42872132972) a créé le **Model Roblox Approved `127067628128103`**. L'asset original, avec **3 220 triangles**, **99 groupes géométriques** et **7 matériaux**, est enregistré dans le registre du jeu.

Le serveur charge un unique Model sanitaire propriétaire via `PremiumCrossroadsEntrancePortalAssets`. Le kit client `ApprovedCrossroadsEntrancePortalMeshKit` valide chaque rail `CrossroadGate1..4` et ses deux `CrossroadPost`, y compris la position exacte et l'orientation, puis monte **7 MeshParts approuvées par portail** avant de masquer les trois natives.

**12 Parts source éligibles uniquement sur Crossroads**, mais le budget est Low 0 ; Medium Android 1/PC 2 ; High Android 2/PC 4 portails simultanés. Sous pression graphique forte, les 12 Parts natives redeviennent visibles. La géométrie 3D ne porte aucune collision ni interception de commandes. Le système de réduction réelle de la surface jouable peut fonctionner indépendamment : les positions des portails sont calculées d'après les dimensions originales stockées par `MapBuilder`, sans lire la taille mobile de la plateforme.

Les compteurs client `LocalCrossroadsEntrance3DCount` et `LocalCrossroadsEntranceNativePartsReplaced` quantifient le montage observé ; ils ne sont pas une mesure des FPS, du rendu réel ou du pourcentage global de primitives restant dans le jeu.

**Roblox Studio/Android et publication de la Place** ne sont pas attestés par une fusion GitHub ni par des régressions source.
