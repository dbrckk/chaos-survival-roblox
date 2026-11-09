# Inventaire reproductible de couverture 3D — stations périphériques

**9 novembre 2026, audit statique de `src/server/MapBuilder.lua`, fonction `addPerimeterStations`.** Ceci ne constitue PAS un audit exhaustif de toutes les formes du jeu.

## Méthode

Une station de la carte source contient **23 pièces cosmétiques natives** créées par `piece(...)`. Le nombre inclut les boucles : plateforme incrustée (1), piliers (2), capots inclinés (2), repères lumineux sur piliers (2), traverse (1), boîtier central (1), lentille (1), balise de navigation (1), boîtiers de compresseur (2), turbines d'admission (2), ailes inclinées (2), rails lumineux des compresseurs (2), rotor supérieur (1), blindage du générateur (1) et deux structures propres à la variante (2). Toutes les variantes choisissent exactement une branche finale avec deux pièces. Les quatre stations partagent cette composition.

**Répartition par ensemble 3D authentifié** (types de pièces source, avec remplacement local conditionnel) :

| Kit source intégré | Éléments par station | Exemples exacts |
| --- | ---: | --- |
| ApprovedPerimeterButtressMeshKit | 2 | LeftButtress, RightButtress |
| ApprovedPerimeterMachineryMeshKit | 3 | CoreHousing, CompressorPodL, CompressorPodR |
| ApprovedPerimeterRotorMeshKit | 3 | IntakeTurbineL/R, GeneratorRotor |
| ApprovedPerimeterArmorMeshKit | 4 | Left/RightAngledCap, AngledServiceWingL/R |
| ApprovedPerimeterStructuresMeshKit | 2 | CrossBrace, GeneratorShield |
| **Total ciblé par un vrai mesh original** | **14** | |
| **Restant en géométrie native** | **9** | |

Calcul : **14 / 23 × 100 = 60,87 %** d'éléments station *pris en charge dans le code source par un remplacement MeshPart* ; **9 / 23 × 100 = 39,13 %** restent sous forme native. Sur les cinq variantes × quatre stations = **460 pièces définies**, dont **280 potentiellement substituables** et **180 restant natives**. Il ne s'agit pas de 460 pièces simultanément affichées : une seule carte peut être active et un seul sous-ensemble des stations éligibles est monté suivant la caméra.

Les neuf pièces restant natives par station sont : InlaidStationBase (1), LeftLightNotch/RightLightNotch (2), CoreLens (1), WayfindingInset (1), PodDataRailL/R (2), plus les deux pièces spécifiques de variante (2). Plusieurs sont des balises fonctionnelles de lisibilité, dont le remplacement par un mesh n'est pas nécessairement souhaitable.

## Limites essentielles

Le chiffre **60,87 % n'est PAS le pourcentage de tout Chaos Survival**. Les éléments de bâtiments, lobby, plateformes, armes, effets, skybox, architecture, cartes et décors locaux n'ont pas été inventoriés à l'échelle du runtime dans cet audit. Le nombre de MeshParts effectivement visibles est de plus dépendant de la qualité graphique, de la distance caméra, de la pression VFX, du streaming et de l'issue du chargement Roblox. En Low, ces kits optionnels utilisent leurs primitives de secours, donc le nombre de substitutions visibles est **0/23** dans cette famille et non 60,87 %. Même en High, les limites de 2 stations Android / 3 PC empêchent d'assimiler ce taux à un comptage simultané de tous les objets.

## Vérification future

À la prochaine validation Roblox Engine, compter réellement les `Original3DAssetId` installés par kit et les primitives natives visibles pour chaque variante en conditions Low/Medium/High, puis auditer tous les autres ensembles décoratifs avant toute **estimation globale**. Le dernier upload public attesté reste P2 (commit ae4ae044e991ef4ca28a991991f2e11b9df49c84). La source actuelle ne prouve pas le rendu en jeu publié.
