# P4 — Traverse forgée et bouclier de générateur originaux sur Android Low

**12 novembre 2026.** Modification GitHub uniquement. Aucune mise à jour
de la place Roblox ni test réel de FPS Android n'est revendiqué.

## Audit concret des stations

Dans chacune des cinq arènes (Classic, Towers, Crossroads, Orbital,
Harbor), `MapBuilder.addPerimeterStations` génère quatre véritables
stations `PerimeterStationNorth/East/South/West`, chacune avec
deux grandes pièces de décor non physiques encore cubiques sur Low :

| Pièce native | Taille (studs) | Source originale créateur approuvée |
| --- | --- | --- |
| `CrossBrace` (traverse métallique haute) | 9.1 × 0.65 × 1.25 | `108452611210970` |
| `GeneratorShield` (écran de générateur) | 4 × 0.55 × 1.4 | `113687802206554` |

Ces deux modèles originaux ont été importés et modérés `Approved`,
sont constitués **chacun de sept vrais MeshParts** et sont chargés
côté serveur via `PremiumPerimeterStructuresAssets`, avec
validation des volumes, de la provenance et du contenu non scripté.
Sur Medium/High leur remplacement fonctionnait déjà.
Sur Low le kit interdisait totalement le rendu via `CAPS.Low=0`.

## Modifications

- `ApprovedPerimeterStructuresMeshKit` autorise désormais
  **exactement une station complète** de sculptures originales
  à `112 studs` maximum de la caméra en qualité Low à
  `OptionalVfxPressure==0`.
- **Deux modèles × sept MeshParts = 14 MeshParts maximum** sur
  la seule station sélectionnée. La limite n'ajoute aucun asset :
  le code réutilise les deux sources approuvées existantes,
  le LOD partagé et le dossier budgété
  `ApprovedPerimeterStructuresLocal`.
- La rétention de 16 studs sur les modèles résidents évite
  les oscillations d'activation. Sur Medium, 1 station à 170 studs ;
  sur High, 3 stations à 245 studs (High tactile : 2).
  Ces règles préexistantes restent inchangées.
- À la **pression graphique 1**, le calcul
  `math.floor(1 * .5)` retire automatiquement le duo sur Low.
  À la pression 2 le duo reste désactivé. Les deux rectangles
  natifs redeviennent visibles.
- L'affichage est **atomique** : les deux sources doivent être
  vérifiées, ajustées, composées de 7 MeshParts chacune,
  positionnées et publiées avant que `CrossBrace` et
  `GeneratorShield` soient masqués. Un import manquant ou
  incomplet conserve les deux blocs natifs.
- Les éléments permanents de la station restent affichés :
  `InlaidStationBase` (sol), `CoreLens` (lentille),
  `WayfindingInset`, `LeftLightNotch`, `RightLightNotch`,
  ainsi que les autres modèles P4 déjà modernisés.
- Les 14 MeshParts sont décoratifs et non physiques
  (`CanCollide=false`, `CanTouch=false`,
  `CanQuery=false`, `CastShadow=false`). Aucun danger,
  collision, marqueur de route, toucher ou joueur ne change.
- Une source retirée, un modèle incomplet, un changement d'arène,
  la perte de la station ou la suppression d'un modèle par le
  gestionnaire de budget déclenche la restauration native.
- Aucune nouvelle texture, lumière, boucle `RenderStepped`,
  `Heartbeat`, requête `AssetService` cliente,
  `RemoteEvent` ou physique réseau.

## Validation Roblox Engine / Android restant à faire

1. Sur un smartphone Android Low à pression zéro, rejoindre chaque
   arène et se rapprocher de `PerimeterStationNorth` ou d'une
   autre station à moins de 112 studs.
2. Vérifier qu'**une seule station** dispose de deux sculptures
   `OriginalPerimeterStructure3D_CrossBrace` et
   `OriginalPerimeterStructure3D_GeneratorShield`, avec sept
   MeshParts chacune. Les deux natives doivent être masquées
   uniquement après le double montage.
3. Contrôler `LocalApprovedPerimeterStructureStationCount <= 1`
   et `LocalPerimeterPrimitiveStructuralBlocksReplaced <= 2`
   sur Low (un compteur à 2 exige le montage effectif complet).
4. Forcer `OptionalVfxPressure=1`, puis 2, puis simuler le retrait
   d'une seule source : les deux blocs natifs reviennent et les
   deux sculptures disparaissent sans artefact.
5. Vérifier les avertissements de catastrophe, la surface jouable,
   le masquage sous streaming et les superpositions avec les
   autres monuments périphériques.
6. Comparer captures, FPS, p95, mémoire et transitions caméra
   avec la version précédente sur un Android Low réel.

Les assertions GitHub de
`tools/verify_original_3d_budget_census.py` contrôlent les
quotas, IDs d'assets approuvés, compte exact de MeshParts,
l'atomicité, les éléments natifs protégés et la pression graphique.
Elles **ne remplacent pas** l'essai Roblox Engine ni une mesure
des performances sur mobile.
