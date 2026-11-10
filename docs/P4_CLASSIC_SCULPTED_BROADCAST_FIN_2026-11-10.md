# P4 — Classic : quatre ailerons 3D de diffusion

10 novembre 2026. Nouvelle géométrie originale conçue pour
`ClassicBroadcastFin1..4` générés par `addVariantLandmarks` :
deux joues aéroprofilées sculptées, nervures longitudinales,
raccords fraisés, panneaux en retrait et marqueurs lumineux.
Aucun volume de collision n'est ajouté.

Une unique source OBJ de sept matériaux couvre les deux orientations
orthogonales du décor : **5.46 × 15.92 × 1.76 studs**,
rotation de 90° pour les `Fin1..2` dont le grand axe natif est Z.
Les **quatre `ClassicBroadcastGlow` restent natifs**, donc leurs
couleurs/animations et leur rendu sont indépendants de la sculpture.

La nouvelle géométrie est soumise aux validations source (triangles,
centrage/enveloppe, sept primitives glTF, UV, normales, tangentes,
identité des quatre positions natives), puis à une importation
Roblox Model propriétaire **une seule fois**, sans jamais publier
la Place. Aucun asset ID ne doit être inventé.

**Statut de ce lot source :** ne pas annoncer de remplacement effectif
avant réception d'un ID Roblox de modèle, modération Approved, ajout au
registre et installation d'un client kit LOD réversible. La QA
Studio/Android et le FPS mesuré sont également hors de ce seul lot.

## Approbation Roblox et intégration runtime

Le workflow [#42866820903](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42866820903) a importé la source originale et prouvé la modération Roblox **Approved**, ID de Model propriétaire `123049626693705`. Cette ID est enregistrée dans `roblox-asset-registry.json`, jamais utilisée comme un `MeshPart.MeshId` inventé.

`PremiumClassicBroadcastFinAssets` assainit une seule fois ce Model en **sept MeshParts** validées, avant de le publier comme modèle de référence en `ReplicatedStorage`. `ApprovedClassicBroadcastFinMeshKit` le clone et l'oriente sur les quatre vraies `ClassicBroadcastFin`, en conservant systématiquement les quatre `ClassicBroadcastGlow` et l'intégralité de la physique de la carte. Les quatre formes source sont **éligibles au remplacement**, non nécessairement affichées simultanément.

Budget simultané : Low 0, Medium Android 1/PC 2, High Android 2/PC 4, réduction supplémentaire si pression visuelle. Disparition de la source, mutation, streaming et changement de carte restaurent les natives. Les compteurs client `LocalClassicFinMeshCount` et `LocalClassicFinPrimitivesReplaced` suivent le nombre effectivement actif.

**Pas de publication Roblox Place automatique** : celle-ci exige un pipeline de release séparé, avec vérifications de jeu. Test Roblox Studio, captures Android et FPS réels restent non attestés par les seuls tests source.
