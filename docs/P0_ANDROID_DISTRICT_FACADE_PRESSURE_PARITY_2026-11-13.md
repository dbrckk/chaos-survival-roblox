# Chaos Survival — budget Android : façades 3D et coques latérales synchronisées

**Date :** 13 novembre 2026. **Branche :** `main`. **Code moteur validé :** `78c0992d829cb4ead1fc8b8c0fec2dbbf58a4dea`.

## Défaut constaté

Les coques latérales 3D de `ApprovedDistrictSidewallMeshKit` limitaient déjà le nombre de modèles selon les qualités Low/Medium/High, la présence d'un écran tactile et l'attribut `OptionalVfxPressure`. En revanche, `PremiumDistrictFacadeMeshKit` continuait d'allouer jusqu'à **1 / 5 / 12 façades**, même si leurs coques latérales avaient été libérées sous pression GPU. Le client Android pouvait donc conserver des façades premium seules, inutilement coûteuses, alors que le joueur voyait à nouveau les cinq masses latérales primitives natives.

## Correction appliquée

La fonction pure `PremiumDistrictFacadeMeshKit.residentBudget(tier,touch,pressure)` définit la limite de modèles de façade 3D **avant sélection et clonage**. Le propriétaire de caméra `scenery-lod.client.lua` communique maintenant au kit de façade le **même** état tactile et la **même** valeur `OptionalVfxPressure` qu'au kit des coques latérales.

| Tier / appareil | Normal (pression 0) | Pression 1 | Pression 2 |
|:--|--:|--:|--:|
| Low, tactile ou PC | 1 | 0 | 0 |
| Medium, Android tactile | **3** | **1** | 0 |
| Medium, PC | 5 | 2 | 0 |
| High, Android tactile | **8** | **4** | 0 |
| High, PC | 12 | 6 | 0 |

Ces nombres concernent les **modèles d'origine approuvés simultanément résidents côté client** ; ils ne sont pas des garanties de modèles visibles ni des FPS mesurés. Les plafonds des vraies coques latérales restent inchangés, leurs imports et les quatre assets de façade approuvés aussi.

Lorsqu'un modèle de façade est retiré, `PremiumDistrictFacadeMeshKit.clear()` désactive le marqueur local `LocalApprovedDistrictFacadeMounted` et rétablit les parties de toit natives précédemment masquées. En Low, la dépendance existante retire alors immédiatement l'unique coque latérale liée si elle est encore présente. Le vrai `Base`, les portes, signaux de navigation et collisions ne sont jamais supprimés. Le prochain passage LOD sain peut remonter les mêmes originaux approuvés.

## Tests réalisés

- [Contrôle de source des budgets Android : succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43427670794) sur le commit `78c0992d`.
- [Build Validation : succès](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43427670800) sur le **même commit**.
- [Roblox Open Cloud Engine — sept suites réussies](https://github.com/dbrckk/chaos-survival-roblox/actions/runs/43427748790), sur le **même commit**. Le nouveau scénario `native-premium-fallback.spec.luau` reconstruit la **véritable arène Classic** avec `MapBuilder`, monte une façade de fixture vérifiée sur `DistrictNorth1`, masque un vrai `AngledRoofL` serveur non collidable, force la pression Low 1, vérifie sa restauration, teste le rétablissement à pression 0 puis l'éviction à pression Medium 2. Toutes les assertions de colliders physiques sont conservées. La fixture n'est pas un asset de production.
- Aucun test de ce chantier ne prouve un gain FPS chiffré sur un téléphone Android réel ni l'état visuel du Roblox Place déjà public. **Aucune publication Roblox n'a été effectuée.**

## Suite du chantier visuel

L'inventaire moteur des cinq variantes contient toujours les stocks natifs initiaux **2 248 pièces `ArenaDistrictArchitecture`, 2 080 bordures et 800 supports de plateformes**, car ces géométries sont le repli natif du serveur. Le recensement client `LocalDistrict3DStates16` (états `B/F/S/N/-`) permet de choisir les bâtiments visibles qui ne reçoivent pas encore les vrais modèles 3D. **Ne pas confondre stock source initial, modèles conditionnellement remplaçables et pourcentage de finition réel du jeu.**
