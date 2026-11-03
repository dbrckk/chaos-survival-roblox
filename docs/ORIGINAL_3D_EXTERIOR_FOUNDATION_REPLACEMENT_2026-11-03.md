# Authentique châssis 3D sous les six monuments extérieurs — 3 novembre 2026

## Problème concret
Les six modèles Roblox originaux et approuvés étaient déjà importés dans `Original3DScenery`, mais leur base visuelle restait construite avec **4 à 11 blocs Part/WedgePart** `OriginalFoundationVisual`. La géométrie importée paraissait posée sur des boîtes Roblox ordinaires.

## Remplacement effectivement implémenté dans la source
- Nouveau `src/client/ApprovedFoundationChassisMeshKit.lua` : utilise **exclusivement** le vrai modèle approuvé `OriginalUnderdeckChassis` (`84582262145054` ; 3 072 triangles, 7 matériaux), déjà chargé, assaini et publié une fois côté serveur par `PremiumRouteMeshAssets`. Aucune nouvelle requête Roblox, aucune texture ou ID inventés.
- Insère un vrai châssis MeshPart ajusté aux dimensions et à l'orientation de la `FoundationShoulder` des modèles `Original3DScenery` proches. Le dessus du vrai mesh est au niveau du dessus de l'ancien socle. Toutes ses pièces restent **sans collision, touch, query ou ombre**, sous la géométrie principale, en dehors de la zone jouable.
- Une fois la véritable géométrie installée et vérifiée, masque les `OriginalFoundationVisual` primitifs. Toute perte de template, de streaming, de LOD, de caméra, de carte ou tout shrink restitue exactement les transparences natives. Les sols et colliders serveur sont inchangés.
- Un seul pilote : `scenery-lod.client.lua`, boucle existante 0,65/0,90 s. **Low 0, Medium 1 à moins de 215 studs, High 2 à moins de 300 studs** ; pas de boucle RenderStepped/Heartbeat supplémentaire.
- Le nouveau compteur client `LocalApprovedFoundationChassis3DCount` reflète les copies réellement montées, **pas** une preuve de rendu photoréaliste ou de performance Android.

## Résultat attendu et limites
Sur les monuments effectivement proches, leurs socles rectangulaires natifs disparaissent au profit d'un véritable châssis industriel creux et sculpté. Les modèles trop étroits pour l'import sans déformation restent sur le fallback d'origine ; pas de faux MeshId ni de destruction définitive.

**État : implémentation GitHub source uniquement.** Ne pas déclarer le lot publié ni validé sur appareil sans preuve. Avant publication publique, exécuter au SHA exact `Build Validation` puis les cinq suites moteur `Roblox Open Cloud Engine Tests`, ensuite le workflow de publication gardée. Sur Android, contrôler le contact visuel mesh/scène, le streaming, les reflets PBR et les FPS. Ce lot ne remplace pas encore toutes les décorations, silhouettes, interfaces et structures primitives des cinq cartes.
