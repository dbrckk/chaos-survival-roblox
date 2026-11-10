# P4 — Crossroads : vrai portique 3D forgé ouvert

## Sculpture source, 10 novembre 2026

Le générateur `tools/generate_original_variant_crossroads_gantry.py`
remplace la silhouette de la poutre `CrossroadGantry1..4` par une
création **originale**, avec deux poutres continues profilées, une
âme latérale triangulée, des renforts et un évidement central.

Le portique mesure environ **27,92 × 3,60 × 2,74 studs**.
L'ouverture au milieu doit préserver la visibilité de la barre
`CrossroadSignal1..4`, existante et indépendante.
Le même modèle 3D sera tourné de 90° pour les deux portiques orientés
le long de Z. Il n'ajoute aucun volume de collision, capteur ou joueur.

La CI teste les triangles et sept matériaux OBJ/glTF, l'enveloppe,
la provenance et les quatre positions natives. Un import contrôlé
de Model Roblox se déclenche une fois après fusion de ce fichier
workflow sur `main` : **aucune publication de Place**.

L'intégration runtime doit impérativement attendre un vrai ID de
l'asset avec `Moderation: Approved`, puis masquer la poutre
native uniquement si sept MeshParts authentiques sont montées.
Les signaux ne doivent pas être masqués et le contrôle LOD mobile
ne doit pas multiplier les appels AssetService.

**Limite :** la validation géométrique par CI n'est pas une vérification
du rendu ou du FPS dans Roblox Studio/Android.
