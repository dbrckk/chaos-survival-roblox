# P4 — Horizon sud Crossroads : échangeur de fret entièrement sculpté

**2026-11-10 — changement GitHub, pas de Roblox Place publique publiée ni de test graphique Roblox Studio.**

## Asset original vérifié
[GitHub Actions #42842143479](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42842143479) a validé l'OBJ et le glTF original, **13 392 triangles**, sept matériaux PBR, géométrie triangulée, UV, normales et tangentes. Dimensions source **18,14954 × 17,1 × 4,6 studs**, échelle monde **2,8**. Roblox Model propriétaire **`77870668100712`**, **Moderation: Approved**.

Source : `tools/generate_original_south_crossroads_exchange.py`. Le modèle contient un noyau structurel à douze facettes, des poutres de fourche ajourées et inclinées, des nez de manutention sculptés, des contrepoids cylindriques travaillés, des indicateurs industriels et une cabine de contrôle détaillée à fenêtres encastrées.

## Couverture exacte : 13/13 éléments cosmétiques
Le kit `src/client/ApprovedSouthCrossroadsExchangeMeshKit.lua` n'opère que sur `GeneratedMap/Arena` de variante **Crossroads**, sur `Decor/SouthHorizonMonument` déclaré `ChaosDistantScenery` :
- `Foundation` (Part 47×2×13) et `FloorInset` (Part 39×0,3×10)
- `ExchangeCore` (Part 8×39×8)
- `WestFork`, `EastFork` (Parts 21×2,4×5,5, inclinaison −/+14° Z)
- `WestFreightArm`, `EastFreightArm` (WedgeParts 9×4,8×6,4, inversion Y du côté ouest)
- `WestCounterweight`, `EastCounterweight` (Parts 5×8×5,5)
- `WestSignal`, `EastSignal` (Parts 7×0,32×0,4)
- `CentralSwitchCab` (Part 10×5×7) et `CabWindow` (Part 7×2,2×0,28)

Le contexte vérifie classe, dimensions, CFrame, ancrage, absence de collisions/touch/queries et présence de toutes les formes. Le serveur `PremiumSouthCrossroadsExchangeAssets.lua` valide précisément **7 MeshParts** cosmétiques et leur enveloppe. Il ne charge que le Model propriétaire authentique et refuse tout script ou asset invalide.

## Repli et performance
Le client monte les sept MeshParts **avant de masquer les 13 éléments natifs**. Le mécanisme de restauration utilise `BasePart`, permettant le retour correct des deux `WedgePart` et des onze `Part`, avec leurs transparences initiales. Les MeshParts sont ancrés, sans ombres, non physiques. Le kit réutilise le sampler LOD existant et le budget visuel partagé ; Low, pression graphique, carte invalide, Model source absent et streaming incomplet entraînent une restauration native. Aucune nouvelle boucle de rendu ou mécanique de jeu.

Le contrôle `tools/verify_south_crossroads_mesh_fallback.py` vérifie exactitude des treize noms, types, contraintes natives, restauration, attributs de provenance et branchements LOD. Le compteur `LocalSouthCrossroadsPrimitivesReplaced` rapporte uniquement les éléments actuellement masqués.

**Mesure de couverture :** **13/13** formes primitives du *seul monument sud Crossroads* disposent d'une version sculptée dans le code ; ce n'est ni le taux de la carte entière, ni la preuve d'un rendu actif sur Low. Contrôles Roblox Studio, Android et publication publique restent distincts.
