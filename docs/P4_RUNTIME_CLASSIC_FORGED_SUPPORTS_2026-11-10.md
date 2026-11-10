# P4 — Classic : architecture secondaire premium, intégration réelle

**10 novembre 2026 — source seulement ; pas de publication ni de rendu moteur certifié.**

## Source et modération

`tools/generate_original_signature_classic_supports.py` dessine les deux vrais contreforts à douze facettes, deux renforts obliques à dix facettes avec câbles d'effort et raidisseurs, et le panneau télémétrique avec ventilation/bolts en relief. Coordonnées MapBuilder normalisées 1:2 et sept matériaux PBR originaux. La validation initiale #42809261548 a détecté un tube de boulon trop court et a empêché tout import. Correctif appliqué, puis double génération identique et conversion OBJ/glTF authentifiées par le [workflow #42809450851](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42809450851) : **5 924 triangles**, **13,47557 × 19,26613 × 2,47275 studs** source et sept sous-meshes UV/normales/tangentes. **Model Roblox authentique 91717127334369 ; Moderation: Approved.**

## Source d'intégration

`src/server/PremiumClassicForgedSupportsAssets.lua` utilise `AssetService.LoadAssetAsync` après 119 secondes, puis `OriginalMeshScenery.sanitize`. Refus strict d'une source possédant moins/plus de sept MeshParts, scripts, collisions ou mauvaise enveloppe d'origine. Le modèle template reste inert dans ReplicatedStorage.

Le client `src/client/ApprovedClassicForgedSupportsMeshKit.lua` valide `GeneratedMap/Arena`, la variante Classic, la vraie `ArenaSignatureMegastructure` nord à distance du plateau et le vrai socle. Les cinq natives `RelayButtressWest/East` (Part 3,5×33×4,5), `RelaySparWest/East` (Part 1,1×31×1,4, rotation ±21°) et `ServicePanel` (Part 5×3,2×.55) doivent toutes exister, être non physiques, correctement dimensionnées et à leur CFrame attendu. Les **sept natives du mât, des paraboles et de leurs hubs** doivent aussi être présentes pour éviter un remplacement pendant un streaming incomplet, mais elles ne sont jamais modifiées par le nouveau kit.

Le Model original est `ScaleTo` **uniformément**, restauré à environ 26,95 × 38,53 × 4,95 studs, puis monté à sa position géométrique originale (X du monument, Y +19,32, Z -.14). Les sept vraies pièces sont toutes des MeshParts ancrées, Massless, CanCollide/CanTouch/CanQuery false, CastShadow false. **Seules les cinq natives supports sont masquées, et uniquement après montage complet.** Originales et MeshParts sont restaurées/détruites de manière cohérente lors du retrait source, streaming incomplet, modification carte, rétrécissement Base, qualité Low, pression GPU. Aucune mutation des collisions de gameplay, aucune nouvelle boucle RenderStepped ni RemoteEvent.

## LOD et statistiques

Le kit est appelé par la cadence préexistante de `scenery-lod.client.lua`, participe au budget partagé de `VisualBudgetRules.lua` via `ApprovedClassicForgedSupportsLocal` et comptabilise les montages réels avec les attributs `LocalApprovedClassicForgedSupportsCount` et `LocalClassicSupportPrimitivePartsReplaced`. Low : 0 ; Medium/High : au plus un Model de 7 MeshParts ; pression1 retire le Medium et pression2 retire tous. Portées 440/610 studs, rétention 26. Les sept premières primitives du monument Classic sont gérées par un kit distinct ; cette seconde phase rend **12 pièces éligibles sur les 14 natives du monument** en profil élevé, sans affirmer que les 12 apparaissent simultanément ou que tout le jeu possède ce taux.

## Livraison vérifiable

Code source/registre/docs sous revue et intégration prévue sur `main`. Aucune mesure de FPS Android, test en Roblox Engine, capture réelle ni nouvelle publication publique de la Place n'est revendiquée. Le jalon final de publication doit valider le rendu et le budget sur le nouveau SHA exact.
