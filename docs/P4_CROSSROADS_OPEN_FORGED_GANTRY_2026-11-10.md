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

## Import Roblox réel et montage réversible

L'import propriétaire original a produit le Model `90844491148907`,
avec modération **Approved** et provenance vérifiable dans
[GitHub Actions #42864120791](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42864120791).

Le chargeur `PremiumCrossroadsGantryAssets` vérifie et assainit les
**sept MeshParts** propriétaires. Un kit client utilise cette unique source
pour les quatre `CrossroadGantry` authentiques. Il préserve les
`CrossroadSignal`, les collisions et les dimensions du générateur.

La disparition de la source, le changement de carte, une pièce modifiée
ou la réduction du budget LOD déclenchent la restauration des natives.
**Quatre poutres primitives éligibles, uniquement dans Crossroads**,
mais au plus 2 mesh gantries simultanés sur High Android et 4 sur
High PC ; Medium Android 1 / PC 2 ; Low 0.

La compilation CI est un contrôle statique source. Une validation Roblox
Studio/Android de l'ouverture centrale et du FPS reste nécessaire.
Aucune nouvelle publication de la Place publique n'est revendiquée.
