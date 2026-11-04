# Grande finition 3D — dessous, colonnes et jonctions des vraies passerelles

**4 novembre 2026 — source et montage préparés, publication/Android non encore certifiés.**
Base auditée : \`f2db320d67f068940fb2004502ea6cd321556261\`, dépôt \`dbrckk/chaos-survival-roblox\`, branche \`main\`.

## Défaut confirmé dans le code (avant ce lot)

Les cinq carapaces 3D approuvées (\`ApprovedPlatformSideTemplates\`) sont des volumes compacts de 10,6 à 12,3 studs de long. Le code pouvait les monter sur une passerelle de plus de 20 studs, puis masquer *tout* le vrai \`PlatformUnderFrameN\`. Le modèle importé ne couvrait pourtant qu'environ la moitié du sous-châssis. C'était une cause réelle de silhouette interrompue, indépendamment du nombre de Parts.

Simultanément, \`PremiumLargeStructureMeshKit\` utilisait une sélection par \`PlatformN % 4\` ou \`% 8\` pour les colonnes, et ne montait les véritables châssis longs que sur les **premiers** 2/1 decks des parcours suivant l'ordre du dossier. Cela ignorait les vrais grands échangeurs proches caméra. Sur \`SkySpineArchitecture\`, deux \`Undercarriage\` natifs + \`CrossStiffener\` restaient empilés sous les vrais treillis ; sur \`PromenadeArchitecture\`, \`UnderdeckTruss\` pouvait doubler une structure authentique.

## Remplacement géométrique vérifiable

1. **Carapace compacte interdite sur long châssis :** \`PremiumPlatformSideMeshKit\` vérifie à la sélection et au montage que le modèle source, après ScaleTo, couvre au moins **78 % du grand axe et 72 % du petit axe** du vrai collider. Les plateformes de 26 studs passent à leur modèle LongCradle réel. Les anciennes sources Approved restent exactes, pas d'ID nouveau.
2. **Sélection structurale fondée sur les vrais itinéraires :** \`selectNearRouteStructures\` choisit une fois par rebuild de carte/tier les **4 châssis LongCradle High / 2 Medium**, et les plateformes candidates à de vraies colonnes **8 High / 4 Medium**, en calculant la distance au joueur seulement si la caméra est effectivement dans l'arène ; repli sur le vrai centre, classement déterministe. Priorité aux échangeurs Sky Spine #5/#6 et au vrai parcours permanent, pas à des numéros modulo arbitraires.
3. **Garde physique et provenance :** l'owner n'utilise que de vrais \`PlatformN\` \`CanCollide\` ancrés, phase sûre, dimensions admissibles, attribut \`SkySpineStep\` ou \`PromenadeStep\`, et pour les supports des \`PlatformSupportN_M\` réellement présents, ancrés, non physiques. Provenance exacte \`Original3DAssetId\` / \`OwnerVerified\` dans \`ApprovedLargeStructureTemplates\`. Le LongCradle existant ID \`128914328933863\` conserve son seuil géométrique : ≥87 % longueur / ≥76 % largeur.
4. **Suppression des doublons natifs uniquement APRÈS l'authentique mesh :** le même \`PlatformNativeTrimReplacementKit\` masque seulement \`SkySpineN_Undercarriage-1/1\`, \`SkySpineN_CrossStiffener\`, \`PromenadeN_UnderdeckTruss\` si l'index authentique du deck est déclaré \`cradle\`, après l'installation complète du vrai kit. Les originaux gardent leurs attributs propriétaires et peuvent revenir en cas de streaming, suppression, changement de carte ou destruction des vrais MeshParts. Pas de masquage des bords lumineux, des marqueurs de saut, des consoles, des plateformes physiques, ni des messages de danger.
5. **Supports réels sous caméra :** même plafond TOTAL de segments 3D authentiques, **16 modules High et 8 Medium**, distribués sur les vraies plateformes pour lesquelles des piliers natifs existent. Chaque Model vérifié est soudé au support source et réagit à son redimensionnement via le listener existant.
6. **Diagnostics locaux :** \`LocalOriginalNearBridgeCradleCount\` et \`LocalOriginalNearSupportColumnCount\` indiquent seulement les structures réellement montées (pas un FPS, pas une capture). Les anciennes métriques restent en place.

## Budget et limites

- Low : 0 châssis LongCradle, 0 colonne 3D ; la structure native demeure.
- Medium : jusqu'à 2 treillis de 22 studs + 8 segments de colonnes.
- High : jusqu'à 4 treillis de 22 studs + 16 segments de colonnes.
- Les modèles importés se partagent toujours \`ArenaPlatformIdentityLocal\`, déjà inclus dans les budgets 440 / 680 / 900 Parts. Éclairage, physique et navigation ne changent pas. Aucun nouvel \`RunService\`, RemoteEvent, AssetService client, script de polling, clone non approuvé ou boucle RenderStepped.

## Conditions de clôture

- Build Validation, vrai moteur Roblox Open Cloud sur le SHA final, lint/provenance des modèles et source des défauts corrigée.
- Vérifier avec prises de vue authentiques les jonctions de promenades et de Sky Spine, les tailles 12/18/26 studs, les colonnes anciennes et nouvelles, High/Medium/Low ; mesurer directement \`LocalOriginalNearBridgeCradleCount\`, \`LocalOriginalNearSupportColumnCount\` et \`LocalNativeStructuralPartsReplaced\`.
- Tester disappearance/streaming de \`Decor\`, phase Warning/Gone, ShrinkingArena, variation du RouteTier, retour lobby et cycles de qualité. La suppression d'un clone doit rendre au prochain instant le vrai sous-châssis natif, pas un vide.
- Android : 30 minutes sur appareil, FPS/mémoire/latence sous pression ; documenter le taux de vrais MeshParts et l'absence de nouvelles zones praticables fictives.

**État honnête :** les règles source et les garde-fous de montage sont modifiés, mais sans captures ni contrôle appareil on ne peut affirmer que 4/2 châssis sont effectivement affichés ; un template non disponible, une géométrie inadéquate ou le budget global peut réduire la résidence réelle. La publication publique n'est pas déclenchée par ce lot.
