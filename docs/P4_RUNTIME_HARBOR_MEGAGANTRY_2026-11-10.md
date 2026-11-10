# P4 — Grand portique Harbor : intégration source du mesh approuvé

**10 novembre 2026.** Ce document atteste du code source intégré au dépôt, **pas** d'une nouvelle Place Roblox publique.

## Preuves d'authenticité

`tools/generate_original_signature_harbor_gantry.py` produit un réel OBJ original et un glTF aux sept matériaux du projet. Le workflow [#42780163672](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/42780163672) a vérifié **2 940 triangles, 40,8 × 14,0425 × 9,141 studs**, UV/normales/tangentes/7 sous-meshes, puis Roblox a renvoyé le Model ID **124368710235343** et **Moderation: Approved**. Le registre d'assets conserve l'ID exact et le run de provenance.

## Matériaux 3D et substitution atomique

`src/server/PremiumHarborSignatureGantryAssets.lua` importe tardivement l'asset depuis AssetService. Le Model traverse `OriginalMeshScenery.sanitize` et un contrôle strict de la source (7 MeshParts seulement, bornes originales, noncollision). Aucun script tiers ou géométrie étrangère n'est utilisé.

`src/client/ApprovedHarborSignatureGantryMeshKit.lua` ne fonctionne que sur le vrai `GeneratedMap/Arena` de variante Harbor, le socle crédible, et `ArenaSignatureMegastructure` exactement nommé et marqué Harbor. Il vérifie trois natives `Part` avec tailles et CFrames réels : `QuayCraneSpanningBeam` 41×2,1×4,4, `QuayCraneCounterweight` 7×5,8×7 et `QuayControlCab` 7,2×5,4×5,2 studs. Les deux jambes, treuils, deux câbles, le mât météo, la pile de containers et le spreader doivent aussi être présents et restent inchangés.

Le Model original est cloné, dimensionné **uniformément** dans le volume englobant natif **41 × 14,1 × 9,1**, puis positionné au centre original local **(+0 ; +0,35 ; +1,95)** relativement à `QuayCraneSpanningBeam`. Ses sept MeshParts sont ancrés, Massless, CanCollide/CanTouch/CanQuery false, CastShadow false. **Les trois natives sont masquées ensemble seulement après la validation du Model entier.** Aucune nouvelle collision, AnimationController, RemoteEvent ou boucle frame n'est ajoutée.

## Budget Android et restauration

Un seul modèle par variante est montable, selon le sampler existant `scenery-lod.client.lua`, et le dossier `ApprovedHarborSignatureGantryLocal` figure dans `VisualBudgetRules` : budget partagé 440/680/900. Low : 0, Medium/High : au plus un Model (sept MeshParts), portée 440/610 studs, rétention 26. Pression GPU 1 retire les modèles Medium; pression 2 retire tous. Le kit remet les trois natives exactes en cas de source absente, modèle/élément supprimé, changement de carte, réduction de Base, streaming partiel, passage Low ou pression GPU importante. Attributs clients `LocalApprovedHarborSignatureGantryCount` et `LocalHarborSignaturePrimitiveBlocksReplaced` dénombrent uniquement les installations effectives.

## Limites de la livraison

Ce modèle remplace potentiellement **trois grands blocs-source** d'Harbor, sans prétendre mesurer l'amélioration du jeu entier. Aucune compilation Luau Roblox Engine, mesure FPS Android, capture de rendu sur mobile, validation visuelle ou publication d'une Place Roblox sur ce commit n'est attestée. Il faudra contrôler la vraie orientation glTF, les décalages cabine/contrepoids et les transitions StreamingEnabled au jalon de release exact-SHA.
