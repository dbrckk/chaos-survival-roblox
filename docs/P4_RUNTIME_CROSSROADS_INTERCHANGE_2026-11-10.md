# P4 — Intégration runtime de l'échangeur Crossroads premium

**10 novembre 2026 : source intégrée, version de jeu non publiée.**

## Origine vérifiée

Le modèle original `signature_crossroads_forged_interchange` a passé les contrôles OBJ/glTF dans l'action [#42778699782](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42778699782) : **4 356 triangles**, sept matériaux PBR et limites **47,68 × 11,73404 × 6,76 studs**. Le vrai Model ID Roblox est **96622579843060**, modéré **Approved**.

## Comportement source

`src/server/PremiumCrossroadsSignatureInterchangeAssets.lua` importe tardivement le Model via AssetService et `OriginalMeshScenery.sanitize`, puis vérifie les sept MeshParts et le gabarit. Le Model n'est utilisé que s'il appartient à l'unique allowlist déjà approuvée.

`src/client/ApprovedCrossroadsSignatureInterchangeMeshKit.lua` valide la vraie carte `GeneratedMap/Arena` Crossroads, la vraie `ArenaSignatureMegastructure`, les deux `ExchangeLeg`, le Switchboard, le SignalPylon/SignalCrown, et **quatre objets exacts** : `LowerExchange` (Part 42×2×6), `UpperExchange` (Part 48×1,3×5,4), `CantileverWest/East` (WedgePart 11×4×7). Les positions relatives, rotations, dimensions et propriétés non physiques sont vérifiées, y compris après streaming.

Le modèle source s'ajuste uniformément à l'union des quatre natives (48×12×7, centre de la structure locale y34) et ses sept MeshParts sont ancrés, `Massless`, `CanCollide/CanTouch/CanQuery=false`, `CastShadow=false`. **Aucun des quatre blocs initiaux n'est masqué avant que tous les nouveaux MeshParts soient montés.** En cas d'asset manquant, source détruite, streaming incomplet, changement d'arène, réduction du socle, baisse du profil graphique ou pression GPU élevée, la visibilité native est restaurée.

Le kit réutilise l'unique cadence LOD de `scenery-lod.client.lua` et le budget de parties locales 440/680/900 de `VisualBudgetRules.lua` ; aucun nouveau RenderStepped, Heartbeat, RemoteEvent ou collider. Low : 0, Medium/High : 1 seul modèle 3D au plus ; profil Medium réduit sous pression1 et tous les profils retirent le modèle sous pression2. Distances 405/580 studs avec hystérésis 25. Attributs de contrôle : `LocalApprovedCrossroadsInterchangeCount` et `LocalCrossroadsInterchangePrimitivePartsReplaced`.

**Limites :** aucune capture Roblox Engine, aucun test FPS Android et aucune nouvelle publication de la Place sur ce commit. Les chiffres reflètent la couverture de quatre natives de la mégastructure Crossroads, pas un taux global d'éléments 3D du jeu.
