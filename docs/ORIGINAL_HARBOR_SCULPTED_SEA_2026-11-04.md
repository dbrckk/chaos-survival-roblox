# Storm Harbor — véritable mer maritime 3D sculptée, sans changer le gameplay

**4 novembre 2026** · Dépôt `dbrckk/chaos-survival-roblox` · **Roblox Model créateur approuvé `111296950975600`** · [preuve de l'import et de la modération Approved](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41889798492). **Ce jalon concerne uniquement le code source et l'asset propriétaire : il ne prouve PAS que le jeu public ait été mis à jour, ni que le résultat ait été réellement photographié sur Android.**

## Problème identifié

Storm Harbor disposait déjà de quatre vraies grues originales animées, d'un grand cargo 3D, de quatre barges 3D, de quais/promenades et d'une grande station de signalisation. Mais **aucune surface d'eau réellement sculptée** n'était définie par les contrôleurs décoratifs : ces bâtiments flottaient encore dans une mer visuellement vide. Améliorer seulement le Fog, l'exposition ou ajouter une simple boîte `Part` de couleur cyan aurait été insuffisant et contraire à l'objectif de suppression des visuels Roblox de base.

## Modèle réalisé et vérifié

Les deux fichiers `tools/generate_original_harbor_sea.py` et `assets/source/chaos_harbor_sea.mtl` fabriquent une **réelle géométrie maritime originale**, avec:

- **6 152 triangles** originaux, **132 groupes sculptés**, **4 896 vertices source** ;
- 7 vrais matériaux séparés `ARMOR/BRUSHED/CARBON/GRIP/ALLOY/CERAMIC/SIGNAL`, **mais avec une PALETTE MARITIME spécifique** et non les anciennes couleurs métalliques. Physique PBR glTF : `metallicFactor = 0.055`, roughness adaptée (0.22 à 0.57), UV/normales/tangentes valides, zéro texture/mesh stock acheté ;
- quatre véritables **nappe d'eau ondulées et triangulées** (vagues géométriques déterministes), fonds sombres au large, bancs littoraux plus clairs, rides sinueuses de vent, courants et zones de reflet, **mousse de bord de quai discontinue** et traînées de remous au nord près du grand cargo ;
- source géométrique **48 × 0.07043 × 48 studs**, importée avec le rapport `1:20` pour obtenir une **mer de 960 × 960 studs** autour du centre. Les MeshParts sont très grands mais **seulement 7 objets non physiques**. Aucun point de ce modèle ne pénètre la zone jouable **320 × 320 studs** : trou intérieur d'au moins **329,6 × 329,6 studs**, validé en parcourant *tous les sommets* de *tous les triangles* avant la création du Model Roblox ;
- positionnement local sous la vraie arène, environ 1 stud sous le dessous de la grande plateforme, sans la recouvrir. La `ShrinkingArena` reste complètement propriété du serveur, ce n'est PAS une mer `Terrain:FillBlock(Water)` qui donnerait aux joueurs une nouvelle physique de nage ni des colliders de secours.
- identifiant owner **`111296950975600`**, modération **Approved** confirmée par l'[opération GitHub Actions](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/41889798492). Registre de provenance mis à **60 modèles Roblox créateur approuvés**.

## Intégration réelle

`src/server/PremiumHarborSeaAssets.lua` n'importe que cet ID, après un chargement différé non bloquant. Le modèle est assaini par `OriginalMeshScenery.sanitize` (aucun script/constraint), contraint à **sept MeshParts non physiques**, à une géométrie source approximativement `48 × 0.07043 × 48`, et à sa provenance approuvée. Il est répliqué dans le dossier autorisé `ReplicatedStorage.ApprovedHarborSeaTemplates.SculptedSea`.

`src/client/HarborSeaMeshKit.lua` vérifie l'ID exact, les mêmes dimensions, l'authenticité du `GeneratedMap.Arena` `VariantId = Harbor`, puis fait **une seule mise à l'échelle `Model:ScaleTo(20)` et un montage local de 7 MeshParts**, sans aucun gameplay ou collision :

- pas de `RunService`, `Heartbeat`, `RenderStepped`, nouvelle boucle, `RemoteEvent`, système de physique, particules spam ou nouveaux éclairages ;
- réutilisation du sampler d'environ 0,65 s de `scenery-lod.client.lua` : chargement seulement lorsque la caméra est réellement proche de l'arène ; contrôle de qualité Low/Medium/High avec budgets de distance 470/610/730 studs et hystérésis de 80 studs ;
- le cœur de l'océan est une **structure essentielle** sur toutes les qualités (une seule source, 7 MeshParts), plutôt que d'effacer entièrement la mer sur Android Low ;
- tous ses MeshParts sont inscrits dans le compteur global de `VisualBudgetRules.LocalFolders` (mêmes limites réelles 440/680/900), donc la scène ne fonctionne pas hors budget ;
- le changement d'arène ou l'absence d'import détruit le modèle local, sans laisser de faux plancher ni toucher à la map. Le comptage client `LocalOriginalHarborSeaCount = 0/1` est un DIAGNOSTIC DE SOURCE MONTÉE et non une mesure visuelle/FPS certifiée.

Le seul changement partagé de convertisseur `tools/obj_to_gltf.py` applique le matériau maritime **uniquement** au fichier `chaos_harbor_sea.mtl` et à sa source `chaos_harbor_sea_apron.obj`; tous les modèles déjà approuvés ont conservé leur pipeline PBR existant.

## Critères objectifs avant mise à jour publique

1. **Build Rojo complet**, registre **60 Models Approved**, vérification géométrique de l'intérieur sec, provenance source et **7 suites moteur Roblox Cloud au SHA exact** ; l'ancien échec `matrix` provenait d'une limite cloud de 20 secondes par test, la même couverture Double Chaos a été divisée en séquences plus courtes dans `tests/engine/gameplay-matrix.spec.luau`.
2. Capture réelle sur **Android Low/Medium/High**, orientation quai nord/sud, eau visible au pied du cargo et des barges, contraste lisible, horizon sans carré apparent, courants/mousse sans motifs répétitifs grossiers.
3. Essai d'une vraie partie avec les 11 catastrophes, `ShrinkingArena`, bots R15, streaming/réduction graphique : l'eau ne donne aucune surface marchable, n'empêche aucune élimination et ne masque aucune plateforme ni danger.
4. Mesures réelles FPS/mémoire (30 minutes), aucune affirmation de performances sans preuve. Si le remplissage GPU du grand océan coûte trop, réduire densité de la source ou limiter certains groupes par tier sans détruire le visuel Low.
5. Envoi public **séparé** après QA, jamais implicitement dans le workflow d'import ou de validation.

**Statut exact :** modèle original approuvé et code intégré ; verdict des vérifications au SHA final et rendu visuel Android non présumés.
