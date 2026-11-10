# P4 — Harbor sud : drydock et lightship originaux à 14 formes

**10 novembre 2026 — code GitHub source, pas de publication de la Place Roblox.**

## Authenticité de l'asset

Le workflow [GitHub Actions #42847077638](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42847077638) a validé un OBJ/glTF original de **13 428 triangles** et **7 matériaux industriels PBR**, dimensions source **16,53571 × 18,36429 × 4,60071 studs**, normales/UV/tangentes vérifiées, SHA256 enregistré. L'asset propriétaire Roblox **`125428569657840`** est **Moderation: Approved**. Le premier candidat dépassait la limite réelle du convertisseur (512 groupes, 16 000 triangles) ; la source a été réoptimisée avec contrôle explicite du budget avant import. Générateur : `tools/generate_original_south_harbor_drydock.py`.

## Cibles exactes : 14/14 éléments du monument Harbor sud

`ApprovedSouthHarborDrydockMeshKit.lua` valide et remplace seulement les quatorze formes non physiques du vrai `GeneratedMap/Arena/Decor/SouthHorizonMonument` en variante **Harbor** :

- `Foundation` (Part 47×2×13), `FloorInset` (Part 39×0,3×10)
- `WestQuayColumn`, `EastQuayColumn` (Parts 4,5×35×4,5), emplacements x = −16 / 16
- `WestQuayCargo`, `EastQuayCargo` (Parts 11×7×8)
- `WestContainerHoist`, `EastContainerHoist` (Parts 0,8×19×1)
- `WestQuayRig`, `EastQuayRig` (**WedgeParts** 8×4×5)
- `HarborLightshipBridge` (Part 41×2,2×5,7)
- `HarborSignalCab` (Part 9×4,5×6)
- `HarborStormLens` (Part 6,8×2×0,22)
- `HarborStormBeacon` (Part 0,8×7×0,8)

Nouvelle sculpture : deux colonnes à douze facettes avec plaques forgées, conteneurs en tôles ondulées 3D, câbles et roues de palan, rigs de grue ajourés, pont suspendu avec vrais treillis, cabine aux montants 3D, optique de tempête et antenne à diodes mécaniques.

## Fonctionnement et repli

`PremiumSouthHarborDrydockAssets.lua` charge le Model authentique, assainit son contenu et refuse les scripts, collisions, objets inconnus ou enveloppes erronées. Le kit client exige tous les noms/types `Part`/`WedgePart`, tailles, CFrames, propriétés non physiques et attributs de provenance. Il place les **7 vrais MeshParts** cosmétiques avant de masquer les **14 primitives** natives. Toutes restent présentes pour restauration de leurs transparences exactes sur Low, distance élevée, pression GPU, changement de carte ou disparition du modèle.

La cadence visuelle LOD existante est réutilisée, sans nouvelle boucle de rendu. Physique, collisions, bots, cartes jouables et modèle Harbor **nord** restent inchangés.

Le test `tools/verify_south_harbor_drydock_fallback.py` couvre toutes les 14 cibles, les WedgeParts, le retour aux natives, la provenance de l'asset et le branchement au budget graphique.

**Périmètre :** 14/14 formes primitives du *seul monument Harbor sud* disposent d'une variante 3D propriétaire approuvée dans le code. Le rendu Roblox Studio, les performances Android et la publication publique n'ont pas été vérifiés. La qualité Low utilise intentionnellement les natives.
