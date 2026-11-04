# Storm Harbor — grande station portuaire 3D originale avec radar et treuil réellement animés

**4 novembre 2026.** Source intégrée à `main`. Asset Roblox propriétaire **`73237902371094` — modération Approved** ([création, validateur de source et import réel #41859877575](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41859877575)). **Ce dossier ne prouve pas à lui seul le rendu Android ni la publication de la place publique.**

## Problème identifié dans le code réel

Le landmark `src/client/arena-hero-scenery.client.lua::buildHarbor` reste dessiné avec **19 morceaux génériques `Part`/`WedgePart`** (fondation, deux énormes piliers, nacelle, mât radar, passerelle, toit, treuil, jambes, rails, contrepoids), en plus d'une sphère de signal maritime existante. Il est placé à l'extérieur du côté Sud de la zone jouable : `base.CFrame * CFrame.new(0,0,base.Size.Z/2+18) * CFrame.Angles(0,pi,0)`. Ces primitives ne correspondent pas à la qualité déjà atteinte par les 4 grues, le cargo et les passerelles 3D. Le seul réglage de l'exposition/Lighting ne corrigerait pas leurs silhouettes rectangulaires.

Le propriétaire `src/client/arena-hero-motion.client.lua` anime **déjà** trois objets natifs de la station par CFrame : `HarborHeroRadarArm`, `HarborHeroHoistCable`, `HarborHeroHoistWeight`. `HarborHeroStormLens` a son propre subtil cycle de transparence et sa réponse visuelle aux catastrophes. **Aucun de ces mouvements ne doit disparaître.**

## Nouvelle sculpture réelle approuvée

`tools/generate_original_harbor_hero_station.py` produit un véritable modèle triangulé/fermé conçu pour ce lieu uniquement : soubassement de contrôle maritime, deux piliers découpés à dix facettes et renforts obliques, montants cannelés, passerelle supérieure à travées, cabine panoramique, vitrage et visières, toiture profilée, mât de radar, tablier et grue latérale métallique avec suspente et caisse usinée.

- **2 816 triangles**, **92 groupes sculptés**, **7 matériaux réels** avec UV, normales et tangentes glTF 2.0.
- Les quatre matériaux fixes **ARMOR / BRUSHED / CERAMIC / SIGNAL** ne contiennent AUCUNE géométrie animée.
- Trois véritables MeshParts indépendants **CARBON = Radar / ALLOY = Cable / GRIP = Weight**. Les contraintes de leur bounding box sont vérifiées dans la source glTF AVANT l'import Roblox.
- Limites de la source vérifiées : **28.39402 × 28.0423 × 7.178 studs**, échelle intentionnelle `0.74`, Y décalé de `20` à l'export pour respecter les bornes du générateur. `Model:ScaleTo(1/0.74)` remet l'œuvre à la taille originelle sur place. Le placement utilise le centre géométrique **(5.05801, -0.60865, 0)**, jamais le pivot arbitraire de l'import Roblox.
- 1 seul import source signé et approuvé : **`73237902371094`**. Ni modèle suspect de toolbox, ni ID déduit ou inventé. Le registre passe de **57 à 58 véritables Models Approved**.

## Intégration runtime

- `src/server/PremiumHarborHeroStationAssets.lua` : chargement Roblox propriétaire du seul ID approuvé, `OriginalMeshScenery.sanitize`, aucune source ni script importé non autorisé, vérification **4 Static + 1 Radar + 1 Cable + 1 Weight**, dimensions exactes, puis réplicat `ApprovedHarborHeroStationTemplates.SignalStation`. Différé de 96 s ; ne bloque ni lobby, ni bots, ni danger. Si échec, les sculptures natives restent.
- `src/client/HarborHeroStationMeshKit.lua` : exige la véritable arène Harbor (320×320 intacte), la scène locale `ArenaHeroSceneryLocal`, ses vrais référents `HarborHeroGantryCrosshead` et `HarborHeroPierFoundation`, l'ensemble des trois composants animés et la sphère maritime native. Vérifie la source entièrement en `MeshPart`, avec chacun des rôles attachés côté serveur.
- Le client positionne **7 MeshParts non physiques** sur la vraie station et masque seulement les anciennes primitives correspondantes avec `Transparency=1` **uniquement quand le modèle complet est présent**. Les anciens Parts restent en place pour contrôler les animations et servir de fallback ; ils ne sont ni supprimés, ni recollisionnés.
- Trois connexions `GetPropertyChangedSignal("CFrame")` (et non une boucle supplémentaire) recopient les transformations relatives radar/treuil/contrepoids dans les trois vrais MeshParts. La lentille d'alerte `HarborHeroStormLens` reste **native, visible, animée et réactive aux catastrophes**, jamais masquée.
- Les quatre MeshParts structurels ne sont pas recalculés à chaque tick ; le nom exact des objets réels et l'ID du Model sont contrôlés. Les changements de scène/qualité/streaming, pertes de pièces, shrink ou absence d'asset provoquent le repli sur la source native.
- Monté sous `workspace.OriginalHarborHeroStationLocal` et intégré à **l'unique contrôleur existant** `scenery-lod.client.lua` + registre `VisualBudgetRules.LocalFolders`. Aucun `RunService`, Heartbeat, boucle, SpotLight, RemoteEvent ou nouvelle partie de collision.

| Budget | Pression graphique 0 | 1 | 2 | Distance caméra |
|---|---:|---:|---:|---:|
| Low Android | 0 | 0 | 0 | — |
| Medium | 1 Model / 7 MeshParts | 0 | 0 | 215 studs + 26 d'hystérésis |
| High | 1 Model / 7 MeshParts | 1 Model | 0 | 345 studs + 42 d'hystérésis |

**Diagnostic client :** `LocalOriginalHarborHeroStationCount=0/1`. Ce compteur dit seulement si le modèle réel est monté, pas s'il a la meilleure apparence sur Android.

## Critères de fin réellement exigés

1. Build Rojo + validation strictement source des **58 imports Approved**, suivie des **7 suites Roblox Cloud au SHA exact** (pas de nouvelle suite unitaire pendant cette phase).
2. Captures authentiques sur Android High/Medium depuis les routes sud et centrales montrant la silhouette du signal maritime, les joints, la cabine et la grue latérale sans vieux blocs visibles au travers du vrai modèle.
3. Plusieurs cycles du radar, du câble et du poids : **les trois sous-meshes doivent suivre les mouvements existants** ; le mât, la cabine, les supports doivent rester fixes ; la lentille doit rester visible durant une catastrophe.
4. Passer Medium→Low→High, `ReduceMotion=true`, sortie/entrée de la caméra, map shrink, StreamingEnabled, changement d'arène ; le fallback doit immédiatement réapparaître sans élément fantôme.
5. Vérifier lisibilité/éclairage (key/fill/rim) et FPS/mémoire 30 minutes sur Android ; traiter les défauts réellement photographiés et ne pas inventer de captures ni de FPS.
6. **Aucune publication de la place** sans confirmation du build/versions et audit de la vraie expérience Roblox.

Ensuite : éventuellement remplacer les dernières petites silhouettes Harbor proches de la caméra, puis industrialiser les remplacements réellement nécessaires aux quatre autres arènes.
