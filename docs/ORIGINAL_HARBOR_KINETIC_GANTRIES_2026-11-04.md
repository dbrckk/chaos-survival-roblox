# Storm Harbor — quatre grues portuaires originales, animées et réversibles

**4 novembre 2026 — intégration au dépôt, pas publication du jeu.**

## Besoin mesuré dans le code

`HarborScenery.lua` conserve quatre vraies grues de décor dans `Arena/Decor/StormHarborGantryFleet` : EastNorth, EastSouth, WestNorth, WestSouth. Une grue était un assemblage de plus de 30 `Part` et `WedgePart`, dont les pylônes, la grue à flèche longue, le chariot, le treuil, des câbles et la charge suspendue. Ces objets sont TOUS non collidables et hors des 320 studs de zone jouable.

**Crucial :** `harbor-gantry-motion.client.lua` anime déjà le vrai chariot natif, la longueur du câble et la charge via `HarborGantryMotionRules.pose`. Un modèle importé entièrement statique détruirait cette qualité visuelle. Le remplacement final doit impérativement hériter de ces animations, pas les masquer.

## Assets originaux vraiment importés

| Modèle | Roblox Model ID | Triangles | Source approuvée | Utilisation |
|---|---:|---:|---|---|
| Cargo — source visuelle fixe | `86657004812104` | 3 400 | [#41854747878](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41854747878) | Référence visuelle, pas utilisée par le runtime final |
| Touret — source visuelle fixe | `82714598831399` | 5 232 | #41854747878 | Référence visuelle, pas utilisée par le runtime final |
| **Cargo — véritable 3D cinématique** | **`75684193304551`** | **3 400** | [#41856104459](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41856104459) | **EastNorth + WestNorth** |
| **Touret — véritable 3D cinématique** | **`98809955094422`** | **5 232** | #41856104459 | **EastSouth + WestSouth** |

Tous les Model IDs correspondent à des imports Roblox sur le créateur autorisé, avec modération **Approved**, et aucun secret publié. Chaque source utilise **sept matériaux 3D réels** avec UV/normales/tangentes, tirés de `tools/generate_original_harbor_gantry.py`. Les géométries comprennent de vraies colonnes creuses à dix côtés, appuis et flancs mécaniques, suspentes triangulées, poutre de 44 studs, motorisation, treuil, cargaison maritime ou cylindre à câble avec bobinage 3D réel.

### Pourquoi deux autres imports cinématiques ont été nécessaires

Le convertisseur glTF standard regroupe toutes les pièces partageant le même matériau. Les deux **premiers** Models Approved mélangeaient les triangles des pylônes, des câbles et de la charge au sein d'un même MeshPart, ce qui rendait impossible l'animation de la charge sans déplacer des éléments fixes du bâtiment. Les deux Models cinématiques emploient donc une palette authentique à **7 matériaux dont 3 réservés aux groupes Trolley, Cable et Load**. Chacun des trois éléments mobiles est un MeshPart indépendant ; les quatre autres MeshParts portent le portique fixe. Aucun faux mouvement d'ensemble.

## Contrat runtime et sécurité

- `PremiumHarborGantryAssets.lua` charge **uniquement** les deux IDs cinématiques Approved via `AssetService.LoadAssetAsync`, après les éléments de gameplay. `OriginalMeshScenery.sanitize` supprime tout script/constraint/effect importé ; validation des tailles source, des sept vrais MeshParts et de la cardinalité exacte des rôles **Static=4, Trolley=1, Cable=1, Load=1** avant que le clone ne soit disponible au client.
- `HarborGantryKineticMeshKit.lua` reconnaît seulement les quatre noms natifs exacts, leur vrai `GantrySector`, les vrais `MainCrossgirder` / `TrolleyCabin` / `HoistCable` / `CargoSpreader` / `ContainerArmor` ou `CableDrum`. Aucun autre Model même renommé ne peut bénéficier du montage.
- Les sept MeshParts sont **cosmétiques non physiques**, sous un dossier local `OriginalHarborKineticGantryLocal`, et alignés sur les vrais paliers en utilisant le centre source vérifié `(0,-0.00526,0)` décalé de `-18` studs en hauteur. Chaque modèle suit la vraie rotation native X/Z du port.
- **Mouvement sans deuxième boucle :** trois connexions CFrame aux objets natifs déjà animés (chariot, câble, charge), et une à la propriété `Size` du vrai câble. Les trois MeshParts importés calculent les déplacements relatifs aux poses natives de repos, tandis que les quatre MeshParts structuraux restent totalement immobiles. L'effet `ReduceMotion` continue à s'appliquer via le propriétaire d'animation existant.
- Les 30+ Parts natives restent présentes. Leurs `Transparency` locales sont mises à 1 uniquement lorsque **les sept MeshParts originaux** sont présents et que le contrat du vrai navire est valide. Le contrôleur existant `SceneryLod` peut conserver `LocalTransparencyModifier` ; cela ne déplace aucun collider serveur, ne supprime aucun objet original et ne retire aucun avertissement. Si un import manque, si un modèle cesse d'exister, si on passe en Low, en cas de streaming ou de changement d'arène, le fallback visuel original est restauré.
- Aucun nouveau `RunService`, `Heartbeat`, `RenderStepped`, boucle, `RemoteEvent`, `Light` ni `SurfaceGui`. Uniquement le sampler caméra existant `scenery-lod.client.lua` et la vraie animation déjà propriétaire du port.

## Budgets Android

| Qualité graphique | Pression 0 | Pression 1 | Pression 2 |
|---|---:|---:|---:|
| Low | 0 | 0 | 0 |
| Medium | 2 grues / 14 MeshParts | 1 / 7 | 0 |
| High | 4 grues / 28 MeshParts | 2 / 14 | 0 |

Distance Medium 170 studs, High 345 studs, hystérésis 24/36 studs. Tous les MeshParts sont comptés par `VisualBudgetRules.LocalFolders` dans les budgets déjà existants de **440/680/900 Parts**. Les anciennes grues conservent leur Low natif, mais ne sont **pas** remplacées par de simples cubes dans la version Medium ou High.

## Gates avant publication (à faire, ne pas inventer)

1. Rojo build, lint, registre des assets approuvés, couverture des **7 suites moteur Roblox Cloud**, au SHA exact.
2. Première vraie partie Harbor sur Android Medium/High : vérifier quatre structures distinctes, orientation des avant-bras, coques sans duplication, cadrage des pistes, nonobstruction de l'aire jouable.
3. Faire tourner le chariot, le câble et le conteneur/touret pendant plusieurs cycles : vérifier une **animation cohérente des trois MeshParts mobiles**, aucun composant statique déplacé, pas de fixation de fil flottant.
4. Réduire la qualité, `ReduceMotion=true`, quitter/rejoindre, changer de carte, faire une ShrinkingArena et provoquer une pause/streaming : l'ancien décor doit toujours réapparaître lorsqu'un modèle n'est plus valide, sans connexe ou pièce perdue.
5. Vérifier 30 minutes de jeu sur appareil, FPS/p95, mémoire, budget de meshes, distance/popping, le cycle complet Lobby → vote → round → résultat.
6. Aucune promesse de livraison publique avant inspection de la vraie version Roblox Creator et publication séparée autorisée.

**Diagnostics client :** `LocalOriginalHarborKineticGantryCount` (0..4) et `LocalOriginalHarborKineticMeshPartCount` (0..28). Il s'agit d'une preuve d'instances montées, PAS de FPS, d'image Android ni de rendu final certifié.

**Prochaine cible visuelle après validation :** la congruence de la silhouette et des animations de l'ensemble du port (cargo, grues, quais, passerelles), puis traitement premium des autres arènes sans diminuer leurs propres mécaniques.
