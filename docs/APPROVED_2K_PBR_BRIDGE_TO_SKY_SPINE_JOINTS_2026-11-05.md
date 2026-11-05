# VIS-010 / VIS-PBR — matériaux 2K continus de la passerelle au grand portique Sky Spine

**5 novembre 2026 — dépôt `dbrckk/chaos-survival-roblox`.** Base publique `968a49da8ad05132decc7135514efd02d2f7a025`. Ce lot crée du code source, pas une mise en ligne.

## Défaut observé dans le code

Les véritables modèles UV/tangentes de passerelles `PremiumSkybridgeModule` (Roblox Approved **94023662427980**) et d'arches `OriginalSkySpineCrown` (Approved **71492051540032**) étaient déjà montés aux parcours physiques. Pourtant, les `SurfaceAppearance` 2K approuvés étaient appliqués seulement aux `PremiumGroundTile` du plancher. La jonction visuelle passerelle/portique réunissait donc les modèles originaux mais pas leur vocabulaire de matériaux de gros plan.

## Amélioration livrée en code

- Nouvelle logique `PremiumRoutePbrKit`, strictement cosmétique, qui réutilise les **16 Image IDs déjà approuvés** (`OriginalGroundPbrTemplates`, quatre familles RGBA/Normal/Roughness/Metallic, serialized `SurfaceAppearance`). Aucune nouvelle image ni tentative de modification de propriété protégée Roblox.
- Le PBR va uniquement sur **les MeshParts à nom explicite ARMOR/ALLOY/BRUSHED/CERAMIC** de modèles approuvés : protections, tôles, alliages et céramiques. **CARBON, GRIP et SIGNAL** (contraste antidérapant, guidage lumineux et danger) sont conservés sans recouvrement.
- La même famille colorimétrique est utilisée aux jonctions : Classic = DiamondArmor, Towers = BrushedTitanium, Crossroads/Harbor = OxidizedSteel, Orbital = ReactorCeramic. Les composants de séparation ALLOY/BRUSHED restent en titane brossé ; CERAMIC reste une céramique originale.
- Le rendu est cohérent **par passerelle entière** (tous les vrais modèles du segment sélectionné), jamais seulement un bout d'une même passerelle. Pas de mesh artificiel créé pour remplir le vide ; les modèles de route restent soumis à la vérification de couverture physique et au repli natif.
- Les changements de \`CollapsePhase\` / \`BridgeShutterPhase\` / \`CanCollide\` libèrent le revêtement 2K du pont **immédiatement par le listener physique existant**, en même temps que le retour du panneau de sol ; aucun délai de LOD avant la restauration du guidage.\n- Les anciennes apparences `SurfaceAppearance` natives d'import sont **préservées**, détachées temporairement et restaurées à la désactivation, au danger, au shrink, au changement d'arène et à la sortie LOD. Une erreur de texture restaure toutes les instances du pont, plutôt que de livrer une moitié revêtue.
- Respect Android : **Low 0**, Medium **1 pont + 1 portique** au maximum si pas de pression, High **1 pont + 1 portique** sur mobile sain. Desktop High **2 ponts + 2 portiques**. Pression 1 : Android = zéro, Desktop High = un ; pression 2 ou option `PbrMaterialsDisabled` = zéro. Les sols 2K déjà présents gardent leurs limites propres ; toutes les apparences sont des clones de templates partagés.
- Les deux owners `PremiumRouteMeshKit` et `SkySpineCrownMeshKit` restent exécutés exclusivement dans l'ancien échantillonneur `scenery-lod.client.lua` ; aucun nouveau `RunService`, `Heartbeat`, `RenderStepped`, service réseau, RemoteEvent, collision, point sûr ou AssetId.
- Télémétrie mesurée sur instances réelles : `LocalOriginalRoutePbr2KModelCount`, `LocalOriginalRoutePbr2KAppearanceCount`, `LocalOriginalSkySpinePbr2KModelCount` et `LocalOriginalSkySpinePbr2KAppearanceCount`. Un nombre de clones ne prouve **ni un FPS ni une bonne texture chargée sur téléphone**.

## Acceptation du jalon

Valider l'engine suite `visual-budget-rules.spec.luau` sur vrais `MeshPart` et `SurfaceAppearance` : copie/restitution de l'original, sources illégitimes rejetées, protection de GRIP/CARBON/SIGNAL, pression/tier/disable, idempotence de la passe, cas des deux modèles approuvés. Puis build Rojo et sept suites moteur sur le SHA final, une seule fois. Sur Android, vérifier la transition **sol–pont–portique**, les différences matières entre cinq arènes, le cas `PbrMaterialsDisabled` et la lisibilité des dangers en pleine catastrophe.

**Reste à faire :** nouveau matériau rendu sur Android, photométrie des vrais portiques, interface de jonction géométrique et plans rapprochés dans les cinq arènes. Ce lot n'invente pas de captures ni d'approbation visuelle.

## 5 novembre — reprise après mise à jour publique : continuité PBR sous streaming

Le client peut recevoir tardivement une nouvelle pièce UV approuvée d'un pont ou d'un portique, ou voir un panneau renommé/reconfiguré pendant le streaming. Avant ce correctif, le cache PBR ne contrôlait que les anciens revêtements : la nouvelle pièce pouvait rester nue malgré le modèle toujours actif. Le contrôle d'intégrité vérifie désormais **toutes les pièces MeshPart éligibles**, leur revêtement original et l'absence de revêtement sur les panneaux de signalisation. En cas de changement, le propriétaire de la caméra reconstruit **la finition de l'entrée entière**, restaure les facteurs importés et respecte le même budget Android. Aucun nouvel asset, aucun render loop et aucune collision. Régression ajoutée aux tests moteur existants pour l'arrivée tardive d'un panneau et sa transformation en panneau SIGNAL.

Ce lot n'est **pas publié** sur Roblox ; le dernier jeu public reste le SHA `968a49d` jusqu'à un prochain jalon explicitement autorisé.
